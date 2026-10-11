import SwiftUI

/// Animated "The Other Side" night sea under an aurora (Metal, via `.colorEffect`).
/// Shader source: `TheOtherSide.metal`. The water is anchored to the bottom band
/// of the frame so the centred timer sits over the sky.
///
/// ponytail: shares the process-wide `shaderEpoch` (see StarNestBackground) so the
/// timer heartbeat can't reset the clock and cause a one-second sawtooth.
///
/// Renders at half size then 2×-upscales: this is the heaviest background here
/// (aurora raymarch + boat sphere-trace + water reflections). If it still drops
/// frames, lower `AURORA_STEPS` / `BOAT_STEPS` in the .metal first.
struct TheOtherSideBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = Float(shaderEpoch.distance(to: context.date))
            GeometryReader { proxy in
                let half = CGSize(width: proxy.size.width / 2, height: proxy.size.height / 2)
                Rectangle()
                    .fill(.black)
                    .colorEffect(
                        ShaderLibrary.theOtherSide(
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
