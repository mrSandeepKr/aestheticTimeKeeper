import SwiftData

/// The ONE store both targets open — a SwiftData container whose SQLite file lives
/// in the App Group container. The app writes `AppState`, the widget reads the same
/// file directly. Change a model once here and every consumer sees it: no parallel
/// structs, no manual sync layer.
public enum SharedModelContainer {
    public static let shared: ModelContainer = {
        let config = ModelConfiguration(groupContainer: .identifier(AppGroup.identifier))
        do {
            return try ModelContainer(for: AppState.self, configurations: config)
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }()
}