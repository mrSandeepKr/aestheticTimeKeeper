#if os(iOS)
import ActivityKit
import Foundation

public struct TimeKeeperAttributes: ActivityAttributes {
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