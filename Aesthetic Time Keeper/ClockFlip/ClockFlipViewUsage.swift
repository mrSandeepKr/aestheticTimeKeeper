//
//  FlipClockUsage.swift
//  AnimationsPracticeSwiftUI
//
//  Created by Sandeep Kumar on 28/12/24.
//

import Foundation
import SwiftUI
import Vortex

struct ClockFlipViewUsage: View {
    @StateObject var viewModel: ClockFlipViewModel
    @StateObject private var clockState: ClockState
    let animationDuration = 0.6
    
    init(config: ClockFlipViewModel.Config) {
        let state = ClockState()
        _clockState = StateObject(wrappedValue: state)
        _viewModel = StateObject(wrappedValue: ClockFlipViewModel(config: config, clockState: state))
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
            
            ControlButtonsView(clockState: viewModel.clockState)
        }
    }
    
    // MARK: - Private
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let foregroundColor: Color = .gray.opacity(0.9)
    private let backgroundColor: Color = .primary
    
    private var minuteInterface: some View {
        HStack {
            NumberFlipView(
                value: .constant(viewModel.minutes / 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
            
            NumberFlipView(
                value: .constant(viewModel.minutes % 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
        }
    }
    
    private var secondsInterface: some View {
        HStack {
            NumberFlipView(
                value: .constant(viewModel.seconds / 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
            
            NumberFlipView(
                value: .constant(viewModel.seconds % 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
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

#Preview {
    ClockFlipViewUsage(config: .stopwatch(startTime: 100))
        .preferredColorScheme(.light)
}
