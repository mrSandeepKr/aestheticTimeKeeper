import Foundation

/// App ⇄ widget command channel. Widget buttons post a command; the app polls and
/// consumes it on its timer tick. Timer *state* itself is not here — it lives in the
/// shared SwiftData store (`SharedModelContainer`) that both targets open.
public enum AppGroup {
    public static let identifier = "group.com.sandeepKr.practice.Aesthetic-Time-Keeper"

    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    public static func postCommand(_ command: String) {
        sharedDefaults?.set(command, forKey: "pendingWidgetCommand")
    }

    public static func consumePendingCommand() -> String? {
        guard let cmd = sharedDefaults?.string(forKey: "pendingWidgetCommand") else { return nil }
        sharedDefaults?.removeObject(forKey: "pendingWidgetCommand")
        return cmd
    }
}