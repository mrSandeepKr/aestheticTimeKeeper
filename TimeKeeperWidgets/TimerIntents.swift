import SwiftUI
import AppIntents
import SwiftData
import Storage

// MARK: - Pause / Resume Intent

/// Reads the timer state from the shared SwiftData store and posts the matching
/// command. The widget can't write the same SQLite store the app is using, so the
/// actual pause/resume happens in the app.
struct PauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    static var description: IntentDescription = "Pause or resume the running timer"

    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedModelContainer.shared)
        let appState = try? context.fetch(FetchDescriptor<AppState>()).first

        if appState?.runningTimer?.isRunning == true {
            AppGroup.postCommand("pause")
        } else {
            AppGroup.postCommand("resume")
        }

        return .result()
    }
}

// MARK: - Stop / Reset Intent

struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Timer"
    static var description: IntentDescription = "Stop and reset the timer"

    func perform() async throws -> some IntentResult {
        AppGroup.postCommand("stop")
        return .result()
    }
}