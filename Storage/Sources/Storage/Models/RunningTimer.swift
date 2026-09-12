import Foundation

/// A timer in flight. The durable facts are stored (remaining/elapsed); the wall-clock
/// anchor (`startedAt`) lets the live value keep advancing while the app is away.
/// Non-nil `startedAt` IS the running state — `isRunning` is derived, never stored.
/// `total` is the countdown's original duration or the stopwatch's max — the progress
/// bar's denominator, kept on the timer so it survives pause/resume and storage.
public enum RunningTimer: Codable, Hashable, Sendable {
    /// Countdown: `remaining` seconds left at `startedAt` (advances against wall clock while running).
    case timer(remaining: TimeInterval, startedAt: Date?, total: TimeInterval?)
    /// Stopwatch: `elapsed` seconds accumulated at `startedAt` (grows against wall clock while running).
    case stopwatch(elapsed: TimeInterval, startedAt: Date?, total: TimeInterval?)

    /// Fraction denominator: original countdown duration, or stopwatch max.
    public var total: TimeInterval? {
        switch self {
        case .timer(_, _, let total), .stopwatch(_, _, let total): total
        }
    }

    /// Wall-clock instant ticking began; nil while paused.
    public var startedAt: Date? {
        switch self {
        case .timer(_, let startedAt, _), .stopwatch(_, let startedAt, _): startedAt
        }
    }

    public var isRunning: Bool { startedAt != nil }

    public var isTimerMode: Bool {
        if case .timer = self { true } else { false }
    }

    /// Seconds remaining (timer) or elapsed (stopwatch) at `now`.
    public func liveValue(now: Date = .now) -> TimeInterval {
        switch self {
        case .timer(let remaining, let startedAt, _):
            guard let startedAt else { return remaining }
            return max(0, remaining - now.timeIntervalSince(startedAt))
        case .stopwatch(let elapsed, let startedAt, _):
            guard let startedAt else { return elapsed }
            return elapsed + now.timeIntervalSince(startedAt)
        }
    }

    /// End of a running countdown; nil while paused or for stopwatches.
    /// Paused timers don't expire during the pause.
    public var endTime: Date? {
        switch self {
        case .timer(let remaining, let startedAt, _):
            startedAt.map { $0.addingTimeInterval(remaining) }
        case .stopwatch:
            nil
        }
    }

    /// Frozen copy: snapshot the live value and drop the anchor.
    public func pausing(now: Date = .now) -> RunningTimer {
        switch self {
        case .timer(_, _, let total): .timer(remaining: liveValue(now: now), startedAt: nil, total: total)
        case .stopwatch(_, _, let total): .stopwatch(elapsed: liveValue(now: now), startedAt: nil, total: total)
        }
    }

    /// Ticking copy: keep the frozen value and start advancing from `now`.
    public func resuming(now: Date = .now) -> RunningTimer {
        switch self {
        case .timer(let remaining, _, let total): .timer(remaining: remaining, startedAt: now, total: total)
        case .stopwatch(let elapsed, _, let total): .stopwatch(elapsed: elapsed, startedAt: now, total: total)
        }
    }
}