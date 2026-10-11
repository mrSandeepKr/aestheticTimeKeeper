import SwiftUI

/// Animated pink fractal raymarcher (Metal, via `.colorEffect`). Shader source: `PinkFractal.metal`.
///
/// ponytail: shares the process-wide `shaderEpoch` (see StarNestBackground) so the
/// timer heartbeat can't reset the clock and cause a one-second sawtooth.
///
/// Renders the shader at half size, then 2×-upscales it: quarter the fragment work,
/// and this raymarcher was ~25 ms/frame at native res on an M3 (StarNest is ~8 ms).
/// The soft glowy fractal hides the downscale.
struct PinkFractalBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = Float(shaderEpoch.distance(to: context.date))
            GeometryReader { proxy in
                let half = CGSize(width: proxy.size.width / 2, height: proxy.size.height / 2)
                Rectangle()
                    .fill(.black)
                    .colorEffect(
                        ShaderLibrary.pinkFractal(
                            .float2(half),
                            .float(time)
                        )
                    )
                    .frame(width: half.width, height: half.height)
                    .scaleEffect(2)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
    }
}
