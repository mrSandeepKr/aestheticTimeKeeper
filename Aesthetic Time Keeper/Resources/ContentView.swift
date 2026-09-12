import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ClockFlipView(modelContext: modelContext)
            .task { LiveActivityManager.observe(modelContext: modelContext) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { LiveActivityManager.resync() }
            }
    }
}

#Preview {
    ContentView()
}
