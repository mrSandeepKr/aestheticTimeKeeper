//
//  ClockFlipView.swift
//  AestheticTimeKeeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import Foundation
import SwiftUI
import SwiftData
import SharedUI
import Storage

struct ClockFlipView: View {
    @State private var clockState: ClockState
    @State private var sheetHeight: CGFloat = .zero

    init(modelContext: ModelContext) {
        let state = ClockState(modelContext: modelContext)
        _clockState = State(initialValue: state)
    }

    var body: some View {
        ZStack {
            backgroundView(clockState.backgroundStyle)

            timerView(clockState.timerStyle, context: renderContext)

            ControlButtonsView(clockState: clockState)
        }
        .sheet(isPresented: Bindable(clockState).showSettings) {
            SettingsView(clockState: clockState)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
                .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: Bindable(clockState).showAppearance) {
            AppearancePickerView(clockState: clockState)
        }
    }

    private var renderContext: TimerRenderContext {
        TimerRenderContext(minutes: clockState.minutes,
                           seconds: clockState.seconds,
                           isStopped: clockState.isStopped)
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ClockFlipView(modelContext: try! ModelContainer(for: AppState.self).mainContext)
        .preferredColorScheme(.light)
}
