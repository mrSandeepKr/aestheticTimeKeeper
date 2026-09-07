import SwiftUI
import SwiftData
import Storage

@main
struct Aesthetic_Time_KeeperApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: AppState.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}