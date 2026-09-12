#if os(iOS)
import ActivityKit
import Foundation

/// ActivityKit attributes shared by the app (publisher) and the widget (renderer).
public struct TimeKeeperAttributes: ActivityAttributes {
    /// The timer itself — the widget derives everything else from it.
    public struct ContentState: Codable, Hashable, Sendable {
        public var runningTimer: RunningTimer

        public init(runningTimer: RunningTimer) {
            self.runningTimer = runningTimer
        }
    }

    public var name: String

    public init(name: String) {
        self.name = name
    }
}
#endif