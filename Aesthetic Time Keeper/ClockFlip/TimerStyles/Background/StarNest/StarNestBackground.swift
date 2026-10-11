import SwiftUI

/// Animated Star Nest shader (Metal, via `.colorEffect`). Shader source: `StarNest.metal`.
///
/// ponytail: one process-wide epoch, not a per-view `Date()`. The timer heartbeat
/// re-evaluates the parent body every second, which would rebuild the view and reset
/// a per-instance start date — a visible one-second sawtooth. Float precision holds
/// for hours of runtime; past ~days the step would start to show.
/// Shared with `PinkFractalBackground` (same reason).
let shaderEpoch = Date()

struct StarNestBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = Float(shaderEpoch.distance(to: context.date))
            GeometryReader { proxy in
                Rectangle()
                    .fill(.black)
                    .colorEffect(
                        ShaderLibrary.starNest(
                            .float2(proxy.size),
                            .float(time)
                        )
                    )
            }
        }
        .ignoresSafeArea()
    }
}
