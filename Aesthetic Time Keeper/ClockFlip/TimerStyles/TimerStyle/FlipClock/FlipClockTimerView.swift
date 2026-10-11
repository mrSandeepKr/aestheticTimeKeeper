import SwiftUI
import SharedUI

/// The original flip-clock renderer, extracted from `ClockFlipView` so it can be
/// dispatched by style. Reads only `TimerRenderContext` + environment.
struct FlipClockTimerView: View {
    let context: TimerRenderContext
    private let animationDuration: CGFloat = 0.6

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                HStack(spacing: 48) {
                    minuteInterface
                    secondsInterface
                }
            } else {
                VStack {
                    minuteInterface
                    Spacer().frame(height: 48)
                    secondsInterface
                }
            }
        }
    }

    private var foreground: Color {
        colorScheme == .dark ? .black.opacity(0.9) : .gray.opacity(0.9)
    }

    @ViewBuilder
    private var minuteInterface: some View {
        HStack(alignment: .top) {
            NumberFlipView(
                value: .constant(context.minutes / 10),
                foreground: foreground,
                background: .primary,
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                animationDuration: animationDuration)

            VStack(alignment: .trailing, spacing: 0) {
                NumberFlipView(
                    value: .constant(context.minutes % 10),
                    foreground: foreground,
                    background: .primary,
                    size: size,
                    fontSize: fontSize,
                    cornerRadius: 10,
                    animationDuration: animationDuration)

                Text("min")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                    .padding(.trailing, 5)
            }
        }
    }

    @ViewBuilder
    private var secondsInterface: some View {
        HStack(alignment: .top) {
            NumberFlipView(
                value: .constant(context.seconds / 10),
                foreground: foreground,
                background: .primary,
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                animationDuration: animationDuration)

            VStack(alignment: .trailing, spacing: 0) {
                NumberFlipView(
                    value: .constant(context.seconds % 10),
                    foreground: foreground,
                    background: .primary,
                    size: size,
                    fontSize: fontSize,
                    cornerRadius: 10,
                    animationDuration: animationDuration)

                Text("sec")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                    .padding(.trailing, 5)
            }
        }
    }

    private var size: CGSize {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, .regular):
            return .init(width: 300, height: 350)
        case (.compact, .regular):
            return .init(width: 150, height: 200)
        case (.regular, .compact):
            return .init(width: 150, height: 200)
        case (.compact, .compact):
            return .init(width: 150, height: 200)
        case (_, _):
            return .init(width: 200, height: 200)
        }
    }

    private var fontSize: CGFloat {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, .regular):
            return 250
        case (.compact, .regular):
            return 150
        case (.regular, .compact):
            return 200
        case (.compact, .compact):
            return 150
        case (_, _):
            return 150
        }
    }
}
