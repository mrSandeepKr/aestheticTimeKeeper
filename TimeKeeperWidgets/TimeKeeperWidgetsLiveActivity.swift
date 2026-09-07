//
//  TimeKeeperWidgetsLiveActivity.swift
//  TimeKeeperWidgets
//
//  Created by Sandeep Kumar on 07/09/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimeKeeperWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TimeKeeperWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeKeeperWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimeKeeperWidgetsAttributes {
    fileprivate static var preview: TimeKeeperWidgetsAttributes {
        TimeKeeperWidgetsAttributes(name: "World")
    }
}

extension TimeKeeperWidgetsAttributes.ContentState {
    fileprivate static var smiley: TimeKeeperWidgetsAttributes.ContentState {
        TimeKeeperWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimeKeeperWidgetsAttributes.ContentState {
         TimeKeeperWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TimeKeeperWidgetsAttributes.preview) {
   TimeKeeperWidgetsLiveActivity()
} contentStates: {
    TimeKeeperWidgetsAttributes.ContentState.smiley
    TimeKeeperWidgetsAttributes.ContentState.starEyes
}
