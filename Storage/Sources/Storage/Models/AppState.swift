import Foundation
import SwiftData

@Model
public final class AppState {
    public var timeSetting: TimerSetting
    public var runningTimer: RunningTimer?

    // Declared defaults let SwiftData migrate existing rows without a migration plan.
    public var timerStyle: TimerStyle = TimerStyle.flipClock
    public var backgroundStyle: ClockBackground = ClockBackground.snow

    public init(timeSetting: TimerSetting = .timer(300),
                runningTimer: RunningTimer? = nil,
                timerStyle: TimerStyle = .flipClock,
                backgroundStyle: ClockBackground = .snow) {
        self.timeSetting = timeSetting
        self.runningTimer = runningTimer
        self.timerStyle = timerStyle
        self.backgroundStyle = backgroundStyle
    }
}
