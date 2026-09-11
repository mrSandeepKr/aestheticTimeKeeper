import Foundation

public enum TimerSetting: Codable, Equatable, Sendable {
    case timer(TimeInterval)
    case stopwatch(TimeInterval)

    public var duration: TimeInterval {
        switch self {
        case .timer(let d), .stopwatch(let d): d
        }
    }
}