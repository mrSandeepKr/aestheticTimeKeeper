import Foundation
import SwiftData

@Model
public final class AppState {
    public var timeSetting: TimerSetting
    public var runningTimer: RunningTimer?

    public init() {
        self.timeSetting = .timer(300)
    }

    public init(timeSetting: TimerSetting, runningTimer: RunningTimer? = nil) {
        self.timeSetting = timeSetting
        self.runningTimer = runningTimer
    }
}