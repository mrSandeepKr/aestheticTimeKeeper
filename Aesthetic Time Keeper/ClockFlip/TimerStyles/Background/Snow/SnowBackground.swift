import SwiftUI
import Vortex

/// Full-screen drifting snow, built on the Vortex particle system.
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
