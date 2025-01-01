import SwiftUI

// MARK: - View
struct ControlButtonsView: View {
    @StateObject var viewModel: ControlButtonsViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private let foreground = Color(.systemBackground)
    private let background = Color(hex: "#EBB866")

    init(clockState: ClockState, 
         config: ControlButtonsViewConfig = .default) {
        _viewModel = StateObject(wrappedValue: ControlButtonsViewModel(
            clockState: clockState,
            config: config
        ))
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
            if viewModel.isMenuExpanded {
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
            viewModel.handleStopButtonAction()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: viewModel.config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: viewModel.config.popoutButtonSize,
                       height: viewModel.config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(y: verticalSizeClass == .regular ? -viewModel.config.stopButtonOffset : 0)
        .offset(x: verticalSizeClass == .regular ? 0 : -viewModel.config.stopButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.01)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            viewModel.handlePlayPauseButtonAction()
        } label: {
            Image(systemName: viewModel.isStopped ? "play.fill" : "pause.fill")
                .font(.system(size: viewModel.config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: viewModel.config.popoutButtonSize,
                       height: viewModel.config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(y: verticalSizeClass == .regular ? -viewModel.config.playPauseButtonOffset : 0)
        .offset(x: verticalSizeClass == .regular ? 0 : -viewModel.config.playPauseButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.05)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var settingsButton: some View {
        Button {
            viewModel.handleSettingsButtonAction()
        } label: {
            Image(systemName: "gear")
                .font(.system(size: viewModel.config.popoutButtonFont))
                .foregroundColor(foreground)
                .frame(width: viewModel.config.popoutButtonSize,
                       height: viewModel.config.popoutButtonSize)
                .background(background)
                .clipShape(Circle())
        }
        .offset(x: verticalSizeClass == .regular ? -viewModel.config.settingsButtonOffset : 0)
        .offset(y: verticalSizeClass == .regular ? 0 : -viewModel.config.settingsButtonOffset)
        .transition(.asymmetric(
            insertion: .scale.animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.03)),
            removal: .scale
        ))
    }
    
    @ViewBuilder
    private var mainMenuButton: some View {
        Button {
            viewModel.toggleMenu()
        } label: {
            Image(systemName: viewModel.isMenuExpanded ? "xmark.circle.fill" : "ellipsis.circle.fill")
                .font(.system(size: viewModel.config.mainButtonFont))
                .foregroundColor(foreground)
                .frame(width: viewModel.config.mainButton,
                       height: viewModel.config.mainButton)
                .background(background)
                .clipShape(Circle())
                .shadow(radius: 2)
                .rotationEffect(.degrees(viewModel.isMenuExpanded ? 600 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.8),
                          value: viewModel.isMenuExpanded)
        }
    }
}

#Preview {
    ClockFlipViewUsage(config: .stopwatch(startTime: 100))
        .preferredColorScheme(.light)
}
