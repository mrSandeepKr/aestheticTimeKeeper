import SwiftUI
import Combine
import SwiftData
import Storage

@MainActor
final class ClockState: ObservableObject {
    @Published var count: Double = 0
    @Published var isStopped = true
    @Published var showSettings = false

    // ponytail: config derived from storage, not stored separately
    var config: Config {
        switch appState.timeSetting {
        case .timer(let d): .timer(maxCountInSeconds: Int(d))
        case .stopwatch(let d): .stopwatch(startTime: Int(d))
        }
    }

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
        if appState.runningTimer != nil {
            resume()
        }
    }

    // MARK: - Timer

    func updateCount(by val: Double) {
        count += val
    }

    // All timer control lives on AppState (storage); here we just mirror the result.

    func startTimer() {
        appState.startTimer()
        refreshFromStorage()
    }

    func pauseTimer() {
        appState.pauseTimer()
        refreshFromStorage()
    }

    func resumeTimer() {
        appState.resumeTimer()
        refreshFromStorage()
    }

    func togglePlayPause() {
        appState.togglePlayPause()
        refreshFromStorage()
    }

    func stopTimer() {
        appState.stopTimer()
        refreshFromStorage()
    }

    // MARK: - Settings

    func apply(timeSetting: TimerSetting) {
        appState.applyTimeSetting(timeSetting)
        refreshFromStorage()
        objectWillChange.send()
    }

    // MARK: - Private

    private func resume() {
        appState.discardExpiredRunningTimer()
        refreshFromStorage()
    }

    /// Mirror the persisted timer into the display state (`count` is elapsed seconds, same
    /// convention the ticker uses; `isStopped` = nothing running).
    private func refreshFromStorage() {
        guard let running = appState.runningTimer else {
            count = 0
            isStopped = true
            return
        }
        count = displayCount(running: running)
        isStopped = !running.isRunning
    }

    private func displayCount(running: RunningTimer) -> Double {
        switch running {
        case .stopwatch: running.liveValue()
        case .timer: config.maxCount - running.liveValue()
        }
    }

    // MARK: - Configuration

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

@MainActor
class ClockFlipViewModel: ObservableObject {
    
    // MARK: - Internal

    var foregroundColor: Color = .gray.opacity(0.9)
    var backgroundColor: Color = .primary
    
    var minutes: Int {
        config.minutes(from: clockState.count)
    }
    
    var seconds: Int {
        config.seconds(from: clockState.count)
    }
    
    var config: ClockState.Config {
        clockState.config
    }
    
    func updateColorScheme(_ colorScheme: ColorScheme) {
        foregroundColor = colorScheme == .dark ? .black.opacity(0.9) : .gray.opacity(0.9)
        backgroundColor = colorScheme == .dark ? .primary : .primary
    }
    
    let clockState: ClockState
    
    // MARK: - Init
    
    init(clockState: ClockState) {
        self.clockState = clockState
        setupTimer()
    }
    
    // MARK: - Private
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var cancellables = Set<AnyCancellable>()
    
    private func setupTimer() {
        timer
            .sink { [weak self] _ in
                guard let self,
                      !self.clockState.isStopped,
                      self.config.maxCount > self.clockState.count else { return }
                clockState.updateCount(by: 1)
            }
            .store(in: &cancellables)
    }
}
