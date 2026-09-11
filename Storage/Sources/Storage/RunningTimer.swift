import Foundation

/// A timer in flight. The durable facts are stored (remaining/elapsed); the wall-clock
/// anchor (`startedAt`) lets the live value keep advancing while the app is away.
/// Non-nil `startedAt` IS the running state — `isRunning` is derived, never stored.
public enum RunningTimer: Codable, Equatable, Sendable {
    /// Countdown: `remaining` seconds left at `startedAt` (advances against wall clock while running).
    case timer(remaining: TimeInterval, startedAt: Date?)
    /// Stopwatch: `elapsed` seconds accumulated at `startedAt` (grows against wall clock while running).
    case stopwatch(elapsed: TimeInterval, startedAt: Date?)

    /// Wall-clock instant ticking began; nil while paused.
    public var startedAt: Date? {
        switch self {
        case .timer(_, let startedAt), .stopwatch(_, let startedAt): startedAt
        }
    }

    public var isRunning: Bool { startedAt != nil }

    public var isTimerMode: Bool {
        if case .timer = self { return true }
        return false
    }

    /// Seconds remaining (timer) or elapsed (stopwatch) at `now`.
    public func liveValue(now: Date = .now) -> TimeInterval {
        switch self {
        case .timer(let remaining, let startedAt):
            guard let startedAt else { return remaining }
            return max(0, remaining - now.timeIntervalSince(startedAt))
        case .stopwatch(let elapsed, let startedAt):
            guard let startedAt else { return elapsed }
            return elapsed + now.timeIntervalSince(startedAt)
        }
    }

    /// End of a running countdown; nil while paused or for stopwatches.
    /// Paused timers don't expire during the pause.
    public var endTime: Date? {
        switch self {
        case .timer(let remaining, let startedAt):
            startedAt.map { $0.addingTimeInterval(remaining) }
        case .stopwatch:
            nil
        }
    }

    /// Frozen copy: snapshot the live value and drop the anchor.
    public func pausing(now: Date = .now) -> RunningTimer {
        switch self {
        case .timer: .timer(remaining: liveValue(now: now), startedAt: nil)
        case .stopwatch: .stopwatch(elapsed: liveValue(now: now), startedAt: nil)
        }
    }

    /// Ticking copy: keep the frozen value and start advancing from `now`.
    public func resuming(now: Date = .now) -> RunningTimer {
        switch self {
        case .timer(let remaining, _): .timer(remaining: remaining, startedAt: now)
        case .stopwatch(let elapsed, _): .stopwatch(elapsed: elapsed, startedAt: now)
        }
    }
}