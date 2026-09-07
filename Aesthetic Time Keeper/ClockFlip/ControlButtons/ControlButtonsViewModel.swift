//
//  ControlButtonsViewModel.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 28/12/24.
//

import Foundation
import SwiftUI

@MainActor
final class ControlButtonsViewModel: ObservableObject {
    
    // MARK: - Internal
    
    @Published var isMenuExpanded = false
    // Mirrors clockState.isStopped; storage methods own the authoritative value.
    @Published var isStopped = false
    let config: ControlButtonsViewConfig
    var clockState: ClockState
    
    // MARK: - Init
    
    init(clockState: ClockState,
         config: ControlButtonsViewConfig = .default) {
        self.clockState = clockState
        self.config = config
        self.isStopped = clockState.isStopped
    }
    
    // MARK: - Action Handling
    
    func toggleMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isMenuExpanded.toggle()
        }
    }
    
    func handleStopButtonAction() {
        clockState.stopTimer()
        isStopped = true
    }
    
    func handlePlayPauseButtonAction() {
        clockState.togglePlayPause()
        isStopped = clockState.isStopped
    }
    
    func handleSettingsButtonAction() {
        clockState.showSettings = true
        toggleMenu()
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

