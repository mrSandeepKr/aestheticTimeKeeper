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
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if verticalSizeClass == .regular {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    @ViewBuilder
    private var portraitLayout: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                buttonMenu
                    .padding(.bottom, 32)
                    .padding(.trailing, 32)
            }
        }
    }
    
    @ViewBuilder
    private var landscapeLayout: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                buttonMenu
                    .padding(.trailing, 32)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var buttonMenu: some View {
        ZStack {
            if viewModel.isMenuExpanded {
                stopButton
                playPauseButton
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

// MARK: - Preview
#Preview {
    ControlButtonsView(
        clockState: .init(),
        config: ControlButtonsViewConfig(mainButton: 55)
    )
} 
