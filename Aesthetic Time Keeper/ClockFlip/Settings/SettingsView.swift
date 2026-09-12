//
//  SettingsView.swift
//  Aesthetic Time Keeper
//
//  Created by Sandeep Kumar on 30/12/24.
//

import SwiftUI
import SwiftData
import SharedUI
import Storage

struct SettingsView: View {
    let clockState: ClockState
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
        let timeSetting: TimerSetting = {
            switch selectedMode {
            case .stopwatch:
                .stopwatch(TimeInterval(minutes * 60))
            case .timer:
                .timer(TimeInterval(minutes * 60))
            }
        }()
        clockState.apply(timeSetting: timeSetting)
        clockState.showSettings = false
    }
    
    private func dismiss() {
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
                    .foregroundColor(.black)
                    .frame(width: textFrameWidth * 1.2, height: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AestheticColor.warmBrown)
                    )
            }
            .padding(.top, 20)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(width: textFrameWidth * 1.2, height: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.9))
                    )
            }
        }
        .padding([.top, .bottom], 20)
        .onAppear {
            switch clockState.config {
            case .timer(maxCountInSeconds: let seconds):
                selectedMode = .timer
                minutes = seconds / 60
            case .stopwatch(startTime: let seconds):
                selectedMode = .stopwatch
                minutes = seconds / 60
            }
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
    SettingsView(clockState: .init(modelContext: try! ModelContainer(for: AppState.self).mainContext))
}


#Preview {
    ControlButtonsView(clockState: .init(modelContext: try! ModelContainer(for: AppState.self).mainContext),
                       config: .default)
}
