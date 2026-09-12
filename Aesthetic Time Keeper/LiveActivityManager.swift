import ActivityKit
import Observation
import SwiftData
import Storage

@MainActor
enum LiveActivityManager {

    private static var activity: Activity<TimeKeeperAttributes>?
    private static var modelContext: ModelContext?

    static func observe(modelContext: ModelContext) {
        self.modelContext = modelContext

        activity = restoreActivity()

        sync(running: currentAppState?.runningTimer)
        subscribe()
    }
    
    // MARK: - Private

    /// The one persisted `AppState` row, re-fetched on demand.
    private static var currentAppState: AppState? {
        guard let modelContext else { return nil }
        return try? modelContext.fetch(FetchDescriptor<AppState>()).first
    }

    private static func subscribe() {
        guard let appState = currentAppState else { return }
        Task { @MainActor in
            let timers = Observations { appState.runningTimer }
            for await running in timers {
                sync(running: running)
            }
        }
    }
    
    private static func restoreActivity() -> Activity<TimeKeeperAttributes>? {
        // Retire stragglers from older sessions so no ghost timer lingers
        // on the island after a relaunch.
        let existing = Activity<TimeKeeperAttributes>.activities
        let newest = existing.max { $0.id < $1.id }
        for stale in existing where stale.id != newest?.id {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        return newest
    }

    private static func sync(running: RunningTimer?) {
        guard let running else {
            end()
            return
        }
        push(running: running)
    }
    
    private static func end() {
        guard let activity else { return }
        // Capture BEFORE clearing the static: the Task body re-reads the static
        // at execution time, so `activity = nil` would otherwise make end() a no-op.
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    private static func push(running: RunningTimer) {
        let state = TimeKeeperAttributes.ContentState(runningTimer: running)

        // A running countdown is stale at zero, so the system removes the
        // activity then — self-heals even if the app never runs again.
        let staleDate = running.isTimerMode && running.isRunning ? running.endTime : nil

        if let activity {
            Task { await activity.update(.init(state: state, staleDate: staleDate)) }
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            do {
                activity = try Activity.request(
                    attributes: TimeKeeperAttributes(name: running.isTimerMode ? "countdown" : "stopwatch"),
                    content: .init(state: state, staleDate: staleDate),
                    pushType: nil
                )
            } catch {
                print("LiveActivity: failed to start — \(error)")
            }
        }
    }
}
