import SwiftUI
import Storage
import SharedUI

// MARK: - Timer view

struct TimerView: View {
    let state: TimeKeeperAttributes.ContentState
    let config: Config

    struct Config {
        let fontSize: CGFloat
        let cornerRadius: CGFloat
        let padding: CGFloat
        let minHeight: CGFloat
        let minTextWidth: CGFloat
        let showsProgress: Bool
    }

    var body: some View {
        content
            .font(.system(size: config.fontSize, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(width: config.minTextWidth, alignment: .center)
            .frame(minHeight: config.minHeight, alignment: .center)
            .padding(.horizontal, config.padding)
            .background(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(.black.opacity(0.85))
            )
    }

    @ViewBuilder
    private var content: some View {
        // Countdown drains to the end; a stopwatch fills toward its configured
        // max. Both only render with a known total.
        if config.showsProgress,
           let total = state.runningTimer.total, total > 0 {
            VStack(spacing: 4) {
                timerText
                TimerProgressView(state: state)
            }
        } else {
            timerText
        }
    }

    @ViewBuilder
    private var timerText: some View {
        let running = state.runningTimer
        // All three branches render the same digital MM:SS format.
        // The system timer text does NOT zero-pad minutes ("4:32", "90:00" with
        // showsHours: false) — the paused string must match that exactly.
        if running.isRunning, let end = running.endTime {
            Text(timerInterval: Date.now...end, countsDown: true, showsHours: false)
        } else if running.isRunning, let start = running.startedAt {
            // Stopwatch: OS ticks this up from the interval's lower bound. Anchor it
            // at the virtual zero (`startedAt - elapsed`); `startedAt` moves forward
            // on every resume, so anchoring at it resets the display to 0:00.
            let zero = start.addingTimeInterval(-running.liveValue(now: start))
            Text(timerInterval: zero...Date.distantFuture, countsDown: false, showsHours: false)
        } else {
            let value = Int(running.liveValue())
            Text(String(format: "%d:%02d", value / 60, value % 60))
        }
    }
}

extension TimerView.Config {
    static let island = TimerView.Config(fontSize: 22, cornerRadius: 10, padding: 14, minHeight: 42, minTextWidth: 68, showsProgress: false)
    static let lockScreen = TimerView.Config(fontSize: 20, cornerRadius: 8, padding: 12, minHeight: 36, minTextWidth: 62, showsProgress: true)
    static let compact = TimerView.Config(fontSize: 13, cornerRadius: 6, padding: 8, minHeight: 26, minTextWidth: 41, showsProgress: false)
}
