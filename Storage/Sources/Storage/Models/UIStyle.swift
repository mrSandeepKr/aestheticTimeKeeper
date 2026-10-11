import Foundation

/// User-selectable timer renderer, persisted on `AppState`.
///
/// Adding a style = add a case here. The app target's exhaustive switches
/// (`timerView(_:context:)` and `TimerStyle.displayName`) then fail to compile
/// until the new style is wired in — that's the integration checklist.
public enum TimerStyle: String, Codable, CaseIterable, Sendable {
    case flipClock
    case textRotation
}

/// User-selectable full-screen background, persisted on `AppState`.
/// Same contract as `TimerStyle`, dispatched by `backgroundView(_:)`.
public enum ClockBackground: String, Codable, CaseIterable, Sendable {
    case snow
    case starNest
    case plain
}
