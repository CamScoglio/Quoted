//
//  QuotedWidgetLiveActivity.swift
//  QuotedWidget
//
//  Created by Cam Scoglio on 6/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct QuotedWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct QuotedWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuotedWidgetAttributes.self) { context in
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

extension QuotedWidgetAttributes {
    fileprivate static var preview: QuotedWidgetAttributes {
        QuotedWidgetAttributes(name: "World")
    }
}

extension QuotedWidgetAttributes.ContentState {
    fileprivate static var smiley: QuotedWidgetAttributes.ContentState {
        QuotedWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: QuotedWidgetAttributes.ContentState {
         QuotedWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: QuotedWidgetAttributes.preview) {
   QuotedWidgetLiveActivity()
} contentStates: {
    QuotedWidgetAttributes.ContentState.smiley
    QuotedWidgetAttributes.ContentState.starEyes
}
