import ActivityKit
import Observation
import SwiftUI
import Storage

// MARK: - Live Activity Manager

/// Listens to the timer state and owns the Live Activity lifecycle.
/// Nobody calls it directly — nothing here is invoked by the UI.
///
/// The widget renders a running timer with `Text(timerInterval:)` / `Text(.timer)`,
/// which the SYSTEM ticks by itself — so a running timer costs exactly one update
/// (at start). Updates are only pushed for semantic changes (pause / resume / stop),
/// keeping us clear of the iOS 18+ per-second update throttle.
@MainActor
enum LiveActivityManager {

    private static var activity: Activity<TimeKeeperAttributes>?
    private static var lastPush: PushKey?

    private typealias PushKey = (endDate: Date?, startDate: Date?, isRunning: Bool)

    /// Observe `clockState.runningTimer` once at app launch. Syncs immediately so
    /// an existing activity is restored and re-synced on launch.
    static func observe(_ clockState: ClockState) {
        // Keep the newest activity; end any stragglers from older sessions so no
        // ghost timer can linger on the island after a relaunch.
        let existing = Activity<TimeKeeperAttributes>.activities
        let newest = existing.max { $0.id < $1.id }
        for stale in existing where stale.id != newest?.id {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        activity = newest
        track(clockState)
        sync(running: clockState.runningTimer)
    }

    /// Observation-style subscription on `runningTimer`: re-arms itself after
    /// every change, then re-syncs.
    private static func track(_ clockState: ClockState) {
        withObservationTracking {
            MainActor.assumeIsolated {
                _ = clockState.runningTimer
            }
        } onChange: {
            Task { @MainActor in
                track(clockState)
                sync(running: clockState.runningTimer)
            }
        }
    }

    // MARK: - State handling

    private static func sync(running: RunningTimer?) {
        guard let running else {
            endIfActive()
            return
        }

        let key = PushKey(
            endDate: running.isTimerMode ? running.endTime : nil,
            startDate: running.isTimerMode ? nil : running.startedAt,
            isRunning: running.isRunning
        )

        // Digits change every heartbeat, but the anchors don't — only semantic
        // changes (start/pause/resume) reach the activity.
        guard key.endDate != lastPush?.endDate
                || key.startDate != lastPush?.startDate
                || key.isRunning != lastPush?.isRunning else { return }

        if activity == nil {
            start(running: running)
        } else {
            update(running: running)
        }
        lastPush = key
    }

    private static func endIfActive() {
        guard let activity else { return }
        // Capture the instance BEFORE clearing the static: the Task body re-reads
        // the static at execution time, so `activity = nil` below would otherwise
        // make the end() call a silent no-op (the activity never goes away).
        self.activity = nil
        lastPush = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - ActivityKit calls

    /// A running countdown is stale the instant it hits zero: the system removes
    /// the activity then (self-heals even if the app never runs again). Paused
    /// timers and stopwatches never go stale on their own.
    private static func staleDate(for running: RunningTimer) -> Date? {
        running.isTimerMode && running.isRunning ? running.endTime : nil
    }

    private static func content(for running: RunningTimer) -> TimeKeeperAttributes.ContentState {
        let value = running.liveValue()
        return .init(
            displayMinutes: Int(value) / 60,
            displaySeconds: Int(value) % 60,
            endDate: running.isTimerMode ? running.endTime : nil,
            startDate: running.isTimerMode ? nil : running.startedAt,
            isRunning: running.isRunning,
            timerMode: running.isTimerMode ? "countdown" : "stopwatch"
        )
    }

    private static func start(running: RunningTimer) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivity: not started — ActivityAuthorizationInfo.areActivitiesEnabled is false")
            return
        }

        let state = content(for: running)
        let attrs = TimeKeeperAttributes(name: state.timerMode)

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: staleDate(for: running)),
                pushType: nil
            )
        } catch {
            print("LiveActivity: failed to start — \(error)")
        }
    }

    private static func update(running: RunningTimer) {
        guard let activity else { return }

        Task {
            await activity.update(.init(state: content(for: running), staleDate: staleDate(for: running)))
        }
    }
}