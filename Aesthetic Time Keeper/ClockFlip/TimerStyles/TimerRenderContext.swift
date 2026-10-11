import Foundation

/// Everything a timer style needs to draw itself — deliberately storage-free so the
/// same style renders on the main screen, in the appearance picker preview, and
/// (later) inside the widget/Live Activity where there is no `ModelContext`.
struct TimerRenderContext: Equatable, Sendable {
    let minutes: Int
    let seconds: Int
    let isStopped: Bool
}
