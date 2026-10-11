import SwiftUI
import Storage
import UIKit

// MARK: - Dispatch (the single integration point per axis)
//
// Every surface that shows a style — main screen AND picker preview — routes through
// these two functions. Adding an enum case breaks the switch (no `default`) until the
// new view is wired in.

@ViewBuilder
func timerView(_ style: TimerStyle, context: TimerRenderContext) -> some View {
    switch style {
    case .flipClock:    FlipClockTimerView(context: context)
    case .textRotation: TextRotationTimerView(context: context)
    }
}

@ViewBuilder
func backgroundView(_ style: ClockBackground) -> some View {
    switch style {
    case .snow:        SnowBackground()
    case .starNest:    StarNestBackground()
    case .pinkFractal: PinkFractalBackground()
    case .plain:       Color(.systemBackground)
    }
}

// MARK: - Metadata
//
// Also exhaustive on purpose: a new case can't ship without user-facing text.

extension TimerStyle {
    var displayName: String {
        switch self {
        case .flipClock:    "Flip Clock"
        case .textRotation: "Text"
        }
    }

    /// Sample data the picker previews with — no running timer required.
    var sampleContext: TimerRenderContext {
        TimerRenderContext(minutes: 5, seconds: 0, isStopped: true)
    }
}

extension ClockBackground {
    var displayName: String {
        switch self {
        case .snow:        "Snow"
        case .starNest:    "Star Nest"
        case .pinkFractal: "Pink Fractal"
        case .plain:       "Plain"
        }
    }
}
