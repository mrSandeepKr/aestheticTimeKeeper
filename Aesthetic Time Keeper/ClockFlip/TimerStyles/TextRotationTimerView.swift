import SwiftUI
import Foundation

/// Minimal second timer style — proves the add-a-style path end to end.
/// Uses the native numeric content transition instead of a hand-rolled flip.
struct TextRotationTimerView: View {
    let context: TimerRenderContext

    var body: some View {
        Text(String(format: "%02d:%02d", context.minutes, context.seconds))
            .font(.system(size: 110, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary)
            .contentTransition(.numericText(countsDown: false))
            .animation(.snappy, value: context.seconds)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.horizontal, 16)
    }
}
