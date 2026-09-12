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
///   - `LiveActivityManager.observe(modelContext:)` manages the Live Activity
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
    private(set) var appState: AppState

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

        // Heartbeat: tick every second so a countdown that hits zero gets
        // discarded even if the app never re-renders. Idle → no work.
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
        guard appState.runningTimer != nil else { return }
        appState.discardExpiredRunningTimer()
        publish()
    }

    /// Copy the persisted state into the observable surface.
    private func publish() {
        runningTimer = appState.runningTimer
        count = displayCount(running: runningTimer)
        isStopped = runningTimer?.isRunning != true
    }

    private func displayCount(running: RunningTimer?) -> Double {
        guard let running else { return 0 }
        return switch running {
        case .stopwatch: running.liveValue()
        case .timer: config.maxCount - running.liveValue()
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
                Double(maxCount)
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