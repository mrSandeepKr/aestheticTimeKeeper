//
//  ControlButtonsViewModel.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import Foundation
import SwiftUI

final class ControlButtonsViewModel: ObservableObject {
    
    // MARK: - Internal
    
    @Published var isMenuExpanded = false
    let config: ControlButtonsViewConfig
    
    // MARK: - Private

    @Binding private(set) var isStopState: Bool
    @Binding private(set) var count: Double
    
    // MARK: - Init
    
    init(isStopState: Binding<Bool>,
         count: Binding<Double>,
         config: ControlButtonsViewConfig = .default) {
        self._isStopState = isStopState
        self._count = count
        self.config = config
    }
    
    // MARK: - Action Handling
    
    func toggleMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isMenuExpanded.toggle()
        }
    }
    
    func handleStopButtonAction() {
        isStopState = true
        count = 0
    }
    
    func handlePlayPauseButtonAction() {
        isStopState.toggle()
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
    
    static let `default` = ControlButtonsViewConfig(mainButton: 55)
}

// MARK: - Preview
#Preview {
    ControlButtonsView(
        stop: .constant(false),
        count: .constant(0),
        config: ControlButtonsViewConfig(mainButton: 160)
    )
} 
