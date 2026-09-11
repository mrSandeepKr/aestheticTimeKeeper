import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import Storage

// MARK: - Live Activity Widget

struct TimeKeeperLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeKeeperAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region — full flipper display + controls
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        TimerModeIcon(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Status badge
                    VStack {
                        Circle()
                            .fill(context.state.isRunning ? .green : .orange)
                            .frame(width: 8, height: 8)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    FlipperTimerDisplay(
                        minutes: context.state.displayMinutes,
                        seconds: context.state.displaySeconds,
                        digitWidth: 28,
                        digitHeight: 36
                    )
                    .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        Button(intent: PauseResumeTimerIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text(context.state.isRunning ? "Pause" : "Resume")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }

                        Button(intent: StopTimerIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Stop")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // Compact leading — mode icon
                TimerModeIcon(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
            } compactTrailing: {
                // Compact trailing — MM:SS text
                Text("\(String(format: "%02d", context.state.displayMinutes)):\(String(format: "%02d", context.state.displaySeconds))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            } minimal: {
                // Minimal — just the mode icon
                TimerModeIcon(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
            }
            .keylineTint(.white.opacity(0.3))
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<TimeKeeperAttributes>) -> some View {
        ZStack {
            Color.black.opacity(0.9)

            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: context.attributes.name == "stopwatch" ? "stopwatch" : "timer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                // Flipper display
                FlipperTimerDisplay(
                    minutes: context.state.displayMinutes,
                    seconds: context.state.displaySeconds,
                    digitWidth: 22,
                    digitHeight: 30
                )

                Spacer()

                // Status indicator
                if context.state.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Running")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                        Text("Paused")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews

extension TimeKeeperAttributes {
    fileprivate static var preview: TimeKeeperAttributes {
        TimeKeeperAttributes(name: "countdown")
    }
}

extension TimeKeeperAttributes.ContentState {
    fileprivate static var running: TimeKeeperAttributes.ContentState {
        TimeKeeperAttributes.ContentState(displayMinutes: 4, displaySeconds: 32, isRunning: true, timerMode: "countdown")
    }

    fileprivate static var paused: TimeKeeperAttributes.ContentState {
        TimeKeeperAttributes.ContentState(displayMinutes: 2, displaySeconds: 15, isRunning: false, timerMode: "countdown")
    }
}

#Preview("Notification", as: .content, using: TimeKeeperAttributes.preview) {
    TimeKeeperLiveActivity()
} contentStates: {
    TimeKeeperAttributes.ContentState.running
    TimeKeeperAttributes.ContentState.paused
}
