import Foundation
import SwiftData

// Timer control and settings live here so the app and any extension
// (widget, notification service) share ONE implementation of the same persistence rules.
@MainActor
extension AppState {

    public var isIdle: Bool { runningTimer == nil }

    public var isPaused: Bool {
        guard let runningTimer else { return false }
        return !runningTimer.isRunning
    }

    // MARK: - Public

    public func applyTimeSetting(_ setting: TimerSetting) {
        timeSetting = setting
        stopTimer()
    }

    public func togglePlayPause() {
        let now = Date.now
        guard let runningTimer else {
            startTimer(now: now)
            return
        }
        if runningTimer.isRunning {
            pauseTimer(now: now)
        } else {
            resumeTimer(now: now)
        }
    }

    public func stopTimer() {
        runningTimer = nil
        save()
    }

    public func discardExpiredRunningTimer() {
        let now = Date.now
        if let runningTimer,
           let endTime = runningTimer.endTime,
            endTime <= now {
            self.runningTimer = nil
            save()
        }
    }

    // MARK: - Private

    private func save() {
        try? modelContext?.save()
    }
    
    private func startTimer(now: Date) {
        switch timeSetting {
        case .timer(let duration):
            runningTimer = .timer(remaining: duration, startedAt: now)
        case .stopwatch:
            runningTimer = .stopwatch(elapsed: 0, startedAt: now)
        }
        save()
    }
    
    private func pauseTimer(now: Date) {
        guard let runningTimer, runningTimer.isRunning else { return }
        self.runningTimer = runningTimer.pausing(now: now)
        save()
    }

    private func resumeTimer(now: Date) {
        guard let runningTimer, !runningTimer.isRunning else { return }
        self.runningTimer = runningTimer.resuming(now: now)
        save()
    }
}
