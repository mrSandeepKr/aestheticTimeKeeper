#if os(iOS)
import ActivityKit

/// ActivityKit attributes shared by the app (publisher) and the widget (renderer).
public struct TimeKeeperAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var displayMinutes: Int
        public var displaySeconds: Int
        public var isRunning: Bool
        /// "countdown" or "stopwatch"
        public var timerMode: String

        public init(displayMinutes: Int, displaySeconds: Int, isRunning: Bool, timerMode: String) {
            self.displayMinutes = displayMinutes
            self.displaySeconds = displaySeconds
            self.isRunning = isRunning
            self.timerMode = timerMode
        }
    }

    public var name: String

    public init(name: String) {
        self.name = name
    }
}
#endif