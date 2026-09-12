import SwiftUI
import Storage
import SharedUI

struct TimerProgressView: View {
    let state: TimeKeeperAttributes.ContentState

    var body: some View {
        let running = state.runningTimer
        if let total = running.total, total > 0 {
            if let end = running.endTime {
                ProgressView(timerInterval: end.addingTimeInterval(-total)...end, countsDown: true) { } currentValueLabel: { }
                    .tint(AestheticColor.warmGold)
            } else {
                // Stopwatch / paused countdown: static fill from the live value.
                let fraction = min(max(running.liveValue() / total, 0), 1)
                ProgressView(value: fraction)
                    .tint(AestheticColor.warmGold)
            }
        }
    }
}