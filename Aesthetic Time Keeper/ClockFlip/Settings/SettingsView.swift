//
//  SettingsView.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 30/12/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var clockState: ClockState
    @State private var minutes: Int = 5
    @State private var selectedMode: TimerMode = .timer
    private let minMinutes = 5
    private let maxMinutes = 90
    private let interval = 5
    
    private let buttonFontSize: CGFloat = 60
    private var textFontSize: CGFloat {
        buttonFontSize * 0.6
    }
    private let textFrameWidth: CGFloat = 160
    private var spacing: CGFloat {
        buttonFontSize * 0.1
    }
    
    private func doneTapped() {
        clockState.config = {
            switch selectedMode {
            case .stopwatch:
                return .stopwatch(startTime: minutes * 60)
            case .timer:
                return .timer(maxCountInSeconds: minutes * 60)
            }
        }()
        clockState.resetCount()
        clockState.showSettings = false
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                ForEach([TimerMode.timer, TimerMode.stopwatch], id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: mode == .timer ? "timer" : "stopwatch")
                                .font(.system(size: 24))
                            Text(mode == .timer ? "Timer" : "Stopwatch")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMode == mode ? Color.primary.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedMode == mode ? .primary : .secondary)
                    }
                }
            }
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            HStack(spacing: spacing) {
                Button(action: decrementMinutes) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: buttonFontSize))
                        .foregroundColor(minutes <= minMinutes ? .secondary : .primary)
                }
                .disabled(minutes <= minMinutes)
                
                Text("\(minutes) min")
                    .font(.system(size: textFontSize))
                    .fontWeight(.semibold)
                    .frame(minWidth: textFrameWidth)
                
                Button(action: incrementMinutes) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: buttonFontSize))
                        .foregroundColor(minutes >= maxMinutes ? .secondary : .primary)
                }
                .disabled(minutes >= maxMinutes)
            }
            .padding()
            .animation(.easeInOut, value: selectedMode)
            
            Button(action: {
                doneTapped()
            }) {
                Text("Done")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.black) // Warm brown text
                    .frame(width: textFrameWidth * 1.2, height: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "FFE5B4"))
                    )
            }
            .padding(.top, 20)
        }
        .padding(.top, 20)
        .onAppear {
            selectedMode =  {
                switch clockState.config {
                case .timer:
                    return .timer
                case .stopwatch:
                    return .stopwatch
                }
            }()
        }
    }
    
    private func incrementMinutes() {
        guard minutes < maxMinutes else { return }
        minutes += interval
    }
    
    private func decrementMinutes() {
        guard minutes > minMinutes else { return }
        minutes -= interval
    }
}

enum TimerMode {
    case timer
    case stopwatch
}

#Preview {
    SettingsView(clockState: .init())
}


#Preview {
    ControlButtonsView(clockState: .init(),
                       config: .default)
}
