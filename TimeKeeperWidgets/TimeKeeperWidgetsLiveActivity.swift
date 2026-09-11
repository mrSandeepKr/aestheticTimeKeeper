import ActivityKit
import WidgetKit
import SwiftUI
import Storage
import SharedUI

struct TimeKeeperLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeKeeperAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            islandView(context: context)
        }
    }

    // MARK: - Lock Screen

    private func lockScreenView(context: ActivityViewContext<TimeKeeperAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: context.attributes.name == "stopwatch" ? "stopwatch" : "timer")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            TimerView(state: context.state, config: .lockScreen)

            Spacer()

            Text(context.state.isRunning ? "Running" : "Paused")
                .font(.caption2)
                .foregroundStyle(context.state.isRunning ? .green : .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
        .activityBackgroundTint(.black)
    }

    // MARK: - Dynamic Island

    private func islandView(context: ActivityViewContext<TimeKeeperAttributes>) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                VStack {
                    TimerIconView(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 4)
            }

            DynamicIslandExpandedRegion(.trailing) {
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
                TimerView(state: context.state, config: .island)
                    .padding(.top, 4)
            }
        } compactLeading: {
            TimerIconView(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
        } compactTrailing: {
            TimerView(state: context.state, config: .compact)
        } minimal: {
            TimerIconView(mode: context.attributes.name == "stopwatch" ? "stopwatch" : "countdown")
        }
        .keylineTint(AestheticColor.warmGold)
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
        TimeKeeperAttributes.ContentState(
            displayMinutes: 4,
            displaySeconds: 32,
            endDate: Date().addingTimeInterval(4 * 60 + 32),
            startDate: nil,
            isRunning: true,
            timerMode: "countdown"
        )
    }

    fileprivate static var paused: TimeKeeperAttributes.ContentState {
        TimeKeeperAttributes.ContentState(
            displayMinutes: 2,
            displaySeconds: 15,
            endDate: nil,
            startDate: nil,
            isRunning: false,
            timerMode: "countdown"
        )
    }
}

#Preview("Lock Screen", as: .content, using: TimeKeeperAttributes.preview) {
    TimeKeeperLiveActivity()
} contentStates: {
    TimeKeeperAttributes.ContentState.running
    TimeKeeperAttributes.ContentState.paused
}