//
//  AppIntent.swift
//  QuotedWidget
//
//  Created by Cam Scoglio on 6/25/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct RefreshQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Quote"
    static var description = IntentDescription("Get a new random quote")
    
    func perform() async throws -> some IntentResult {
        // Trigger widget refresh
        WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
        return .result()
    }
}
