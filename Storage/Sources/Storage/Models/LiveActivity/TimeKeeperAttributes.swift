#if os(iOS)
import ActivityKit
import Foundation

/// ActivityKit attributes shared by the app (publisher) and the widget (renderer).
public struct TimeKeeperAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var displayMinutes: Int
        public var displaySeconds: Int
        public var endDate: Date?
        public var startDate: Date?
        public var isRunning: Bool
        public var timerMode: String

        public init(displayMinutes: Int, displaySeconds: Int, endDate: Date?, startDate: Date?, isRunning: Bool, timerMode: String) {
            self.displayMinutes = displayMinutes
            self.displaySeconds = displaySeconds
            self.endDate = endDate
            self.startDate = startDate
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