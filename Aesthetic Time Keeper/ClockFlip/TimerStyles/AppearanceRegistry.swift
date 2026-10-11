import SwiftUI
import Storage
import Vortex
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
    case .snow:  SnowBackground()
    case .plain: Color(.systemBackground)
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
        case .snow:  "Snow"
        case .plain: "Plain"
        }
    }
}

// MARK: - Backgrounds

struct SnowBackground: View {
    var body: some View {
        VortexView(createSnow()) {
            Circle()
                .fill(.primary)
                .blur(radius: 7)
                .frame(width: 32)
                .tag("circle")
        }
        .ignoresSafeArea()
    }

    private func createSnow() -> VortexSystem {
        let system = VortexSystem(tags: ["circle"])
        system.position = [0.5, 0]
        system.speed = 0.003
        system.speedVariation = 0.15
        system.lifespan = 7
        system.shape = .box(width: 1, height: 0)
        system.angle = .degrees(180)
        system.angleRange = .degrees(20)
        system.size = 0.15
        system.birthRate = 40
        system.sizeVariation = 0.5
        return system
    }
}
