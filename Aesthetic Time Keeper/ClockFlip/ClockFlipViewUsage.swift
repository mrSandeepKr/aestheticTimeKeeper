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
    
    enum Config {
        case timer(maxCountInSeconds: Int)
        case stopwatch(startTime: Int)
        
        fileprivate var maxCount: Double {
            switch self {
            case .stopwatch(let maxCount),
                 .timer(let maxCount):
                return Double(maxCount)
            }
        }
        
        fileprivate func minutes(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) / 60
            case .timer:
                Int(maxCount - count) / 60
            }
        }
        
        fileprivate func seconds(from count: Double) -> Int {
            switch self {
            case .stopwatch:
                Int(count) % 60
            case .timer:
                Int(maxCount - count) % 60
            }
        }
    }
    
    let config: Config
    let animationDuration = 0.6
    
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
        }
        .onReceive(timer) { _ in
            guard !stop else { return }
            guard config.maxCount > count else {
                return
            }
            
            count += 0.01
        }
    }
    
    // MARK: - Private
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private let foregroundColor: Color = .gray.opacity(0.9)
    private let backgroundColor: Color = .primary
    
    private var minuteInterface: some View {
        HStack {
            ClockFlipView(
                value: .constant(minutes / 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
            
            ClockFlipView(
                value: .constant(minutes % 10),
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
            ClockFlipView(
                value: .constant(seconds / 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
            
            ClockFlipView(
                value: .constant(seconds % 10),
                size: size,
                fontSize: fontSize,
                cornerRadius: 10,
                foreground: foregroundColor,
                background: backgroundColor,
                animationDuration: animationDuration)
        }
    }
    
    @State private var count: Double = 0
    @State private var stop = false
    
    private var minutes: Int {
        config.minutes(from: count)
    }
    
    private var seconds: Int {
        config.seconds(from: count)
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
    
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
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
#Preview {
    ClockFlipViewUsage(config: .timer(maxCountInSeconds: 100))
        .preferredColorScheme(.light)
}
