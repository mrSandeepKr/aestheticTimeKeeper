import Foundation
import SwiftData

// Timer control and settings live here so the app and any extension
// (widget, notification service) share ONE implementation of the same persistence rules.
@MainActor
extension AppState {
    // MARK: - Derived state

    /// True when nothing is running or paused.
    public var isIdle: Bool { runningTimer == nil }

    /// True when a timer exists but is paused.
    public var isPaused: Bool {
        guard let runningTimer else { return false }
        return !runningTimer.isRunning
    }

    // MARK: - Settings

    public func applyTimeSetting(_ setting: TimerSetting) {
        timeSetting = setting
        stopTimer()
    }

    // MARK: - Timer controls

    /// Starts a fresh timer from the current time setting.
    public func startTimer(now: Date = .now) {
        switch timeSetting {
        case .timer(let duration):
            runningTimer = .timer(remaining: duration, startedAt: now)
        case .stopwatch:
            runningTimer = .stopwatch(elapsed: 0, startedAt: now)
        }
        save()
    }

    /// Freezes the running timer, keeping its live value.
    public func pauseTimer(now: Date = .now) {
        guard let runningTimer, runningTimer.isRunning else { return }
        self.runningTimer = runningTimer.pausing(now: now)
        save()
    }

    /// Resumes a paused timer from its frozen value.
    public func resumeTimer(now: Date = .now) {
        guard let runningTimer, !runningTimer.isRunning else { return }
        self.runningTimer = runningTimer.resuming(now: now)
        save()
    }

    /// Play ⇄ pause. Starts fresh when idle.
    public func togglePlayPause(now: Date = .now) {
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

    /// Stops and clears the timer.
    public func stopTimer() {
        runningTimer = nil
        save()
    }

    /// Clears a countdown that has already finished while the app was away.
    /// Paused timers never expire while paused.
    public func discardExpiredRunningTimer(now: Date = .now) {
        if let runningTimer, let endTime = runningTimer.endTime, endTime <= now {
            self.runningTimer = nil
            save()
        }
    }

    // MARK: - Private

    /// The timer model is slow to flush without an explicit save.
    private func save() {
        try? modelContext?.save()
    }
}