import SwiftUI
import SwiftData
import UIKit
import SharedUI
import Storage

// MARK: - View
struct ControlButtonsView: View {
    @State private var isMenuExpanded = false
    let clockState: ClockState
    let config: ControlButtonsViewConfig
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private let foreground = Color(.systemBackground)
    private let background = AestheticColor.warmGold

    init(clockState: ClockState,
         config: ControlButtonsViewConfig = .default) {
        self.clockState = clockState
        self.config = config
    }
    
    var body: some View {
        mainContent
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var mainContent: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                buttonMenu
                    .padding([.bottom, .trailing], 32)
            }
        }
    }
    
    @ViewBuilder
    private var buttonMenu: some View {
        ZStack {
            if isMenuExpanded {
                stopButton
                playPauseButton
                settingsButton
            }
            mainMenuButton
        }
    }
    
    @ViewBuilder
    private var stopButton: some View {
        Button {
            clockState.stopTimer()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: config.popoutButtonSize,
                       height: config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(y: verticalSizeClass == .regular ? -config.stopButtonOffset : 0)
        .offset(x: verticalSizeClass == .regular ? 0 : -config.stopButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.01)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            clockState.togglePlayPause()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: clockState.isStopped ? "play.fill" : "pause.fill")
                .font(.system(size: config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: config.popoutButtonSize,
                       height: config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(y: verticalSizeClass == .regular ? -config.playPauseButtonOffset : 0)
        .offset(x: verticalSizeClass == .regular ? 0 : -config.playPauseButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.05)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        Button {
            clockState.showSettings = true
            toggleMenu()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            Image(systemName: "gear")
                .font(.system(size: config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: config.popoutButtonSize,
                       height: config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(x: verticalSizeClass == .regular ? -config.settingsButtonOffset : 0)
        .offset(y: verticalSizeClass == .regular ? 0 : -config.settingsButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.03)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var mainMenuButton: some View {
        Button {
            toggleMenu()
        } label: {
            Image(systemName: isMenuExpanded ? "xmark.circle.fill" : "ellipsis.circle.fill")
                .font(.system(size: config.mainButtonFont))
                .foregroundColor(foreground)
                .frame(width: config.mainButton,
                       height: config.mainButton)
                .background(background)
                .clipShape(Circle())
                .shadow(radius: 2)
                .rotationEffect(.degrees(isMenuExpanded ? 600 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                          value: isMenuExpanded)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isMenuExpanded)
    }
    
    private func toggleMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isMenuExpanded.toggle()
        }
    }
}

// MARK: - Configuration

struct ControlButtonsViewConfig {
    let mainButton: CGFloat
    
    var popoutButtonSize: CGFloat { mainButton * 0.85 }
    var popoutButtonFont: CGFloat { popoutButtonSize * 0.436 }
    var mainButtonFont: CGFloat { mainButton * 0.436 }
    var stopButtonOffset: CGFloat { mainButton * 2.2 }
    var playPauseButtonOffset: CGFloat { mainButton * 1.1 }
    var settingsButtonOffset: CGFloat { mainButton * 1.1 }
    
    static let `default` = ControlButtonsViewConfig(mainButton: 55)
}

#Preview {
    ClockFlipView(modelContext: try! ModelContainer(for: AppState.self).mainContext)
        .preferredColorScheme(.light)
}