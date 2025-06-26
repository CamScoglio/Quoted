//
//  AppIntent.swift
//  QuotedWidget
//
//  Created by Cam Scoglio on 6/25/25.
//

import WidgetKit
import AppIntents

struct NextQuoteIntent: AppIntent {
    static var title: LocalizedStringResource { "Next Quote" }
    static var description: IntentDescription { "Get the next random quote" }
    
    func perform() async throws -> some IntentResult {
        // Reload all widgets of this kind to fetch a new random quote
        WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
        return .result()
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
