import SwiftUI
import Storage

// MARK: - Timer view

/// The single timer look used on the Lock Screen, the expanded Dynamic Island,
/// and the compact trailing edge. Each surface passes its own `Config` for sizing;
/// the visual is identical everywhere.
///
/// Running → the dark card wraps the system-ticked timer text
/// (`Text(timerInterval:)` / `Text(date, style: .timer)`), so the OS ticks the digits
/// with zero app updates. Paused → the same card with the frozen MM:SS.
struct TimerView: View {
    let state: TimeKeeperAttributes.ContentState
    let config: Config

    struct Config {
        let fontSize: CGFloat
        let cornerRadius: CGFloat
        let padding: CGFloat
        let minHeight: CGFloat
        /// Width reserved for the widest value ("0:00:00") so digits never shift layout.
        let minTextWidth: CGFloat
    }

    var body: some View {
        timerText
            .font(.system(size: config.fontSize, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(width: config.minTextWidth, alignment: .center)
            .frame(height: config.minHeight, alignment: .center)
            .padding(.horizontal, config.padding)
            .background(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(.black.opacity(0.85))
            )
    }

    @ViewBuilder
    private var timerText: some View {
        // All three branches render the same digital MM:SS format.
        // The system timer text does NOT zero-pad minutes ("4:32", "90:00" with
        // showsHours: false) — the paused string must match that exactly.
        if state.isRunning, let end = state.endDate {
            Text(timerInterval: Date.now...end, countsDown: true, showsHours: false)
        } else if state.isRunning, let start = state.startDate {
            Text(timerInterval: start...Date.distantFuture, countsDown: false, showsHours: false)
        } else {
            Text(String(format: "%d:%02d", state.displayMinutes, state.displaySeconds))
        }
    }
}

extension TimerView.Config {
    static let island = TimerView.Config(fontSize: 22, cornerRadius: 10, padding: 14, minHeight: 42, minTextWidth: 68)
    static let lockScreen = TimerView.Config(fontSize: 20, cornerRadius: 8, padding: 12, minHeight: 36, minTextWidth: 62)
    static let compact = TimerView.Config(fontSize: 13, cornerRadius: 6, padding: 8, minHeight: 26, minTextWidth: 41)
}
