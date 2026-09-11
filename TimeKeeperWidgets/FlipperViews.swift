import SwiftUI

// MARK: - Single flipper digit card

struct FlipperDigitCard: View {
    let value: Int
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat

    private var cornerRadius: CGFloat { height * 0.15 }

    var body: some View {
        ZStack {
            // Top half
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(.black.opacity(0.85))
            .frame(height: height / 2)
            .overlay(alignment: .top) {
                digitText
                    .frame(width: width, height: height)
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .top)

            // Bottom half
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(.black.opacity(0.85))
            .frame(height: height / 2)
            .overlay(alignment: .bottom) {
                digitText
                    .frame(width: width, height: height)
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Center divider line
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(height: 1)
                .zIndex(10)
        }
        .frame(width: width, height: height)
    }

    private var digitText: some View {
        Text("\(value)")
            .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
    }
}

// MARK: - Colon separator

struct FlipperColon: View {
    let height: CGFloat

    var body: some View {
        VStack(spacing: height * 0.18) {
            Circle().fill(.white.opacity(0.8)).frame(width: height * 0.1, height: height * 0.1)
            Circle().fill(.white.opacity(0.8)).frame(width: height * 0.1, height: height * 0.1)
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Full MM:SS flipper display

struct FlipperTimerDisplay: View {
    let minutes: Int
    let seconds: Int
    let digitWidth: CGFloat
    let digitHeight: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            FlipperDigitCard(value: minutes / 10, width: digitWidth, height: digitHeight, fontSize: digitHeight * 0.6)
            FlipperDigitCard(value: minutes % 10, width: digitWidth, height: digitHeight, fontSize: digitHeight * 0.6)
            FlipperColon(height: digitHeight)
            FlipperDigitCard(value: seconds / 10, width: digitWidth, height: digitHeight, fontSize: digitHeight * 0.6)
            FlipperDigitCard(value: seconds % 10, width: digitWidth, height: digitHeight, fontSize: digitHeight * 0.6)
        }
    }
}

// MARK: - Mode icon

struct TimerModeIcon: View {
    let mode: String

    var body: some View {
        Image(systemName: mode == "stopwatch" ? "stopwatch" : "timer")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
    }
}
