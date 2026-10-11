import Foundation

/// User-selectable full-screen background, persisted on `AppState`.
/// Same contract as `TimerStyle`, dispatched by `backgroundView(_:)`.
public enum ClockBackground: String, Codable, CaseIterable, Sendable {
    case snow
    case starNest
    case pinkFractal
    case theOtherSide
    case plain
}
