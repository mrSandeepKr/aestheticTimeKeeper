//
//  ClockFlipView.swift
//  AestheticTimeKeeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import Foundation
import SwiftUI
import SwiftData
import Vortex
import SharedUI
import Storage

struct ClockFlipView: View {
    @State private var clockState: ClockState
    @State private var sheetHeight: CGFloat = .zero
    let animationDuration = 0.6
    
    init(modelContext: ModelContext) {
        let state = ClockState(modelContext: modelContext)
        _clockState = State(initialValue: state)
        LiveActivityManager.observe(state)
    }
    
    var body: some View {
        ZStack {
            VortexView(createSnow()) {
                Circle()
                    .fill(.primary)
                    .blur(radius: 7)
                    .frame(width: 32)
                    .tag("circle")
            }
            .ignoresSafeArea()
            
            if verticalSizeClass == .compact {
                HStack(spacing: 48) {
                    Spacer()
                    minuteInterface
                    secondsInterface
                    Spacer()
                }
            } else {
                VStack {
                    Spacer()
                    minuteInterface
                    Spacer().frame(height: 48)
                    secondsInterface
                    Spacer()
                }
            }
            
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
    }
    
    // MARK: - Private
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    private var foreground: Color {
        colorScheme == .dark ? .black.opacity(0.9) : .gray.opacity(0.9)
    }
    
    @ViewBuilder
    private var minuteInterface: some View {
        HStack(alignment: .top) {
            // First NumberFlipView
            NumberFlipView(
                value: .constant(clockState.minutes / 10),
                foreground: foreground,
                background: .primary,
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                animationDuration: animationDuration)
            
            // Second NumberFlipView with a trailing-aligned Text
            VStack(alignment: .trailing, spacing: 0) {
                // Top-aligned NumberFlipView
                NumberFlipView(
                    value: .constant(clockState.minutes % 10),
                    foreground: foreground,
                    background: .primary,
                    size: size,
                    fontSize: fontSize,
                    cornerRadius: 10,
                    animationDuration: animationDuration)
                
                // Text aligned to the trailing edge
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
            // First NumberFlipView
            NumberFlipView(
                value: .constant(clockState.seconds / 10),
                foreground: foreground,
                background: .primary,
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                animationDuration: animationDuration)
            
            // Second NumberFlipView with a trailing-aligned Text
            VStack(alignment: .trailing, spacing: 0) {
                // Top-aligned NumberFlipView
                NumberFlipView(
                    value: .constant(clockState.seconds % 10),
                    foreground: foreground,
                    background: .primary,
                    size: size,
                    fontSize: fontSize,
                    cornerRadius: 10,
                    animationDuration: animationDuration)
                
                // Text aligned to the trailing edge
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
            return  150
        case (_, _):
            return  150
        }
    }
    
    private func createSnow() -> VortexSystem {
        let system = VortexSystem(tags: ["circle"])
        system.position = [0.5, 0]
        system.speed = 0.003
        system.speedVariation = 0.15
        system.lifespan = 7
        system.shape = .box(width: 1, height: 0)
        system.angle = .degrees(180)
        system.angleRange = .degrees(20)
        system.size = 0.15
        system.birthRate = 40
        system.sizeVariation = 0.5
        return system
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