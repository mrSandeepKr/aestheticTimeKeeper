import SwiftUI
import SwiftData
import SharedUI
import Storage

/// Grid of swappable styles. Renders each cell through the SAME dispatchers the main
/// screen uses, so previews can never drift from production. Iterates `allCases`, so a
/// new style shows up here with zero edits to this file.
struct AppearancePickerView: View {
    let clockState: ClockState

    @State private var axis: Axis = .timer

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    private let cellHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 20) {
            Picker("", selection: $axis) {
                ForEach(Axis.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    switch axis {
                    case .timer:
                        ForEach(TimerStyle.allCases, id: \.self) { style in
                            cell(title: style.displayName,
                                 selected: clockState.timerStyle == style,
                                 action: { clockState.setTimerStyle(style) }) {
                                timerView(style, context: style.sampleContext)
                            }
                        }
                    case .background:
                        ForEach(ClockBackground.allCases, id: \.self) { style in
                            cell(title: style.displayName,
                                 selected: clockState.backgroundStyle == style,
                                 action: { clockState.setBackgroundStyle(style) }) {
                                backgroundView(style)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private func cell<Preview: View>(
        title: String,
        selected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                StylePreview { preview() }
                    .frame(height: cellHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selected ? AestheticColor.warmGold : Color.clear, lineWidth: 3)
                    )

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(selected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Renders a style at a fixed reference size, then scales to fit the cell — so every
/// preview is uniformly sized regardless of the style's intrinsic layout.
private struct StylePreview<Content: View>: View {
    let content: Content
    private let reference = CGSize(width: 340, height: 520)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / reference.width,
                            geo.size.height / reference.height)
            content
                .frame(width: reference.width, height: reference.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }
}

private extension AppearancePickerView {
    enum Axis: String, CaseIterable {
        case timer, background
        var title: String { self == .timer ? "Timer" : "Background" }
    }
}

#Preview {
    AppearancePickerView(clockState: .init(modelContext: try! ModelContainer(for: AppState.self).mainContext))
}
