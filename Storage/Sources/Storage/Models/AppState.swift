import Foundation
import SwiftData

@Model
public final class AppState {
    public var timeSetting: TimerSetting
    public var runningTimer: RunningTimer?

    public init(timeSetting: TimerSetting = .timer(300), runningTimer: RunningTimer? = nil) {
        self.timeSetting = timeSetting
        self.runningTimer = runningTimer
    }
}