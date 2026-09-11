import ActivityKit
import SwiftUI
import Storage

// MARK: - Live Activity Manager

/// Manages the lifecycle of the timer Live Activity (Dynamic Island / Lock Screen).
/// Only the app target imports this; the widget reads state from App Group UserDefaults.
@MainActor
enum LiveActivityManager {

    private static var activity: Activity<TimeKeeperAttributes>?

    /// Whether a Live Activity is currently active.
    static var isActive: Bool { activity != nil }

    // MARK: - Start

    /// Start a new Live Activity for the given timer.
    static func start(mode: String, minutes: Int, seconds: Int, isRunning: Bool = true) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivity: not started — ActivityAuthorizationInfo.areActivitiesEnabled is false")
            return
        }

        let attrs = TimeKeeperAttributes(name: mode)
        let state = TimeKeeperAttributes.ContentState(
            displayMinutes: minutes,
            displaySeconds: seconds,
            isRunning: isRunning,
            timerMode: mode
        )

        do {
            activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("LiveActivity: failed to start — \(error)")
        }
    }

    // MARK: - Update

    /// Push a new content state to the running Live Activity.
    static func update(minutes: Int, seconds: Int, isRunning: Bool, mode: String) {
        guard let activity else { return }

        let state = TimeKeeperAttributes.ContentState(
            displayMinutes: minutes,
            displaySeconds: seconds,
            isRunning: isRunning,
            timerMode: mode
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // MARK: - End

    /// End the current Live Activity.
    static func end() {
        guard let activity else { return }

        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    // MARK: - Restore

    /// On app launch, reconnect to an existing Live Activity if one is running.
    static func restoreFromExisting() {
        activity = Activity<TimeKeeperAttributes>.activities.first
    }
}
