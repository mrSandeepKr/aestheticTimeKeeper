import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ClockFlipView(modelContext: modelContext)
            .task { LiveActivityManager.observe(modelContext: modelContext) }
    }
}

#Preview {
    ContentView()
}