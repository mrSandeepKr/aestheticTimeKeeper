import Foundation

public enum RunningTimer: Codable, Equatable, Sendable {
    case timer(startTime: Date, duration: TimeInterval)
    case stopwatch(startTime: Date, duration: TimeInterval)

    public var startTime: Date {
        switch self {
        case .timer(let start, _), .stopwatch(let start, _): start
        }
    }

    public var duration: TimeInterval {
        switch self {
        case .timer(_, let d), .stopwatch(_, let d): d
        }
    }

    public var endTime: Date? {
        switch self {
        case .timer(let start, let duration):
            start.addingTimeInterval(duration)
        case .stopwatch:
            nil
        }
    }
}