import ActivityKit
import Foundation
import Observation
import SwiftData
import Storage

/// Owns the Live Activity lifecycle.
///
/// State changes arrive as a stream from `Observations` on the persisted
/// `AppState.runningTimer`. That stream emits only on semantic changes
/// (start / pause / resume / stop / expiry) — never on the 1 Hz heartbeat — so
/// this stays well inside ActivityKit's update budget.
///
/// Every ActivityKit call goes through one `SerialTaskQueue`, so updates are
/// applied in the order the state changed. A plain `Task { await update }` per
/// change let a stale "running" push land after a "pause", which left the island
/// ticking while the timer was paused.
@MainActor
enum LiveActivityManager {

    private static let activityQueue = SerialTaskQueue()
    private static var activity: Activity<TimeKeeperAttributes>?
    private static var modelContext: ModelContext?
    private static var observationTask: Task<Void, Never>?

    /// Watch the persisted timer and mirror every change into the Live Activity.
    static func observe(modelContext: ModelContext) {
        self.modelContext = modelContext
        activity = adoptExistingActivity()

        // Idempotent: never run two observation loops for one context.
        observationTask?.cancel()
        guard let appState = currentAppState else { return }
        observationTask = Task { @MainActor in
            // The first emission is the current value, so this doubles as initial sync.
            for await running in Observations({ appState.runningTimer }) {
                sync(running)
            }
        }
    }

    /// Re-push the persisted state on foreground return, so a Live Activity that
    /// missed an update while the app was suspended self-corrects.
    static func resync() {
        sync(currentAppState?.runningTimer)
    }

    // MARK: - Private

    /// The one persisted `AppState` row, re-fetched on demand (SwiftData returns
    /// the same instance the UI hub already holds).
    private static var currentAppState: AppState? {
        guard let modelContext else { return nil }
        return try? modelContext.fetch(FetchDescriptor<AppState>()).first
    }

    /// Adopt one existing activity and retire the rest, so no ghost timer lingers
    /// on the island after a relaunch.
    ///
    /// Which one is kept doesn't matter: `Activity.id` is a random UUID, so it
    /// can't be ordered by creation time, and the next observed state reconciles
    /// the retained activity anyway.
    private static func adoptExistingActivity() -> Activity<TimeKeeperAttributes>? {
        let existing = Activity<TimeKeeperAttributes>.activities
        guard let retained = existing.first else { return nil }
        for stale in existing where stale.id != retained.id {
            activityQueue.enqueue { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        return retained
    }

    /// Queue the timer's desired state; runs in order with every other call.
    private static func sync(_ running: RunningTimer?) {
        activityQueue.enqueue {
            if let running {
                await push(running)
            } else {
                await end()
            }
        }
    }

    /// Show `running`, starting the activity if there isn't one yet.
    private static func push(_ running: RunningTimer) async {
        // `total` lives on the timer (Storage) so the widget's progress bar shows
        // a true fraction even after pause/resume cycles (which reset `startedAt`).
        let state = TimeKeeperAttributes.ContentState(runningTimer: running)

        // A running countdown is stale at zero, so the system removes the activity
        // then — self-heals even if the app never runs again.
        let staleDate = running.isTimerMode && running.isRunning ? running.endTime : nil
        let content = ActivityContent(state: state, staleDate: staleDate)

        if let activity {
            await activity.update(content)
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                activity = try Activity.request(
                    attributes: TimeKeeperAttributes(name: running.isTimerMode ? "countdown" : "stopwatch"),
                    content: content,
                    pushType: nil
                )
            } catch {
                print("LiveActivity: failed to start — \(error)")
            }
        }
    }

    private static func end() async {
        guard let activity else { return }
        self.activity = nil
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
