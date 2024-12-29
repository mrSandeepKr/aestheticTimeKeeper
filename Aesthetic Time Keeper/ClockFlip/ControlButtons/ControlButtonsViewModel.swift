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
    @Published var isStopped = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                clockState.isStopped = isStopped
            }
        }
    }
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
        isStopped = true
        clockState.count = 0
    }
    
    func handlePlayPauseButtonAction() {
        isStopped.toggle()
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

