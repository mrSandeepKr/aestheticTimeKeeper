import SwiftUI
import Observation
import SwiftData
import Storage

/// The single reactive hub for the timer.
///
/// `AppState` (SwiftData) stays the persisted truth. In SwiftUI terms this is the
/// screen's one `@Observable` — views just read its properties (observation is
/// automatic) and everyone else observes `runningTimer` for side effects.
///
/// Consumers:
///   - UI renders `minutes` / `seconds` / `isStopped` / `config`
///   - `LiveActivityManager.observe(clockState)` manages the Live Activity
///
/// Every consumer reads the same object, so they can never disagree.
@MainActor
@Observable
final class ClockState {
    // MARK: - State (the single source)

    /// Canonical timer, nil while idle. Re-emitted by the heartbeat every second
    /// while running so the value advances against the wall clock.
    private(set) var runningTimer: RunningTimer?

    /// Display seconds elapsed (stopwatch) or remaining (countdown), same
    /// convention for both modes.
    private(set) var count: Double = 0
    private(set) var isStopped = true
    var showSettings = false

    // ponytail: config derived from storage, not stored separately
    var config: Config {
        switch appState.timeSetting {
        case .timer(let d): .timer(maxCountInSeconds: Int(d))
        case .stopwatch(let d): .stopwatch(startTime: Int(d))
        }
    }

    var minutes: Int { config.minutes(from: count) }
    var seconds: Int { config.seconds(from: count) }

    let modelContext: ModelContext
    var appState: AppState

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let descriptor = FetchDescriptor<AppState>()
        if let existing = try? modelContext.fetch(descriptor).first {
            self.appState = existing
        } else {
            let state = AppState()
            modelContext.insert(state)
            try? modelContext.save()
            self.appState = state
        }
        appState.discardExpiredRunningTimer()
        publish()

        // Heartbeat: tick every second so running timers advance and mailbox
        // commands get applied. Idle + no command → no work.
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    // MARK: - Actions (the only way state changes)

    /// Play ⇄ pause. Starts fresh when idle.
    func togglePlayPause() {
        appState.togglePlayPause()
        publish()
    }

    func stopTimer() {
        appState.stopTimer()
        publish()
    }

    func apply(timeSetting: TimerSetting) {
        appState.applyTimeSetting(timeSetting)
        publish()
    }

    // MARK: - Private

    private var heartbeatTask: Task<Void, Never>?

    private func tick() {
        guard processPendingCommands() || appState.runningTimer != nil else { return }
        appState.discardExpiredRunningTimer()
        publish()
    }

    /// Drain the widget mailbox. Returns true if a command was applied.
    private func processPendingCommands() -> Bool {
        guard let command = AppGroup.consumePendingCommand() else { return false }
        switch command {
        case "toggle":
            // No timer alive = activity should have ended already; ignore.
            guard appState.runningTimer != nil else { return false }
            appState.togglePlayPause()
        case "stop":
            appState.stopTimer()
        default:
            return false
        }
        return true
    }

    /// Copy the persisted state into the observable surface.
    private func publish() {
        runningTimer = appState.runningTimer
        count = displayCount(running: runningTimer)
        isStopped = !(runningTimer?.isRunning ?? false)
    }

    private func displayCount(running: RunningTimer?) -> Double {
        guard let running else { return 0 }
        switch running {
        case .stopwatch: return running.liveValue()
        case .timer: return config.maxCount - running.liveValue()
        }
    }
}

extension ClockState {
    enum Config {
        case timer(maxCountInSeconds: Int)
        case stopwatch(startTime: Int)

        var maxCount: Double {
            switch self {
            case .stopwatch(let maxCount),
                 .timer(let maxCount):
                return Double(maxCount)
            }
        }

        func minutes(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) / 60
            case .timer:
                Int(maxCount - count) / 60
            }
        }

        func seconds(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) % 60
            case .timer:
                Int(maxCount - count) % 60
            }
        }
    }
}