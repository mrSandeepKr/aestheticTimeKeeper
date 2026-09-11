import SwiftUI

// MARK: - Mode icon

struct TimerIconView: View {
    let mode: String

    var body: some View {
        Image(systemName: mode == "stopwatch" ? "stopwatch" : "timer")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
    }
}