import SwiftUI

public struct NumberTextView: View {
    let value: Int
    let fontSize: CGFloat
    let foreground: Color

    public init(value: Int, fontSize: CGFloat, foreground: Color) {
        self.value = value
        self.fontSize = fontSize
        self.foreground = foreground
    }

    public var body: some View {
        ZStack {
            Text("\(value)")
                .font(Font.system(size: fontSize, weight: .medium))
                .foregroundStyle(foreground)
                .lineLimit(1)

            Rectangle()
                .fill(.white)
                .frame(height: 1.5)
                .zIndex(10)
        }
    }
}