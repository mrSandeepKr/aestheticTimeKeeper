import SwiftUI
import SwiftData
import Storage

@main
struct Aesthetic_Time_KeeperApp: App {
    let container: ModelContainer = SharedModelContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}