//
//  NextQuoteIntent.swift
//  QuotedWidgetExtension
//
//  Created by Cam Scoglio on 6/25/25.
//

import AppIntents
import WidgetKit

struct NextQuoteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Next Quote"
    static var description = IntentDescription("Get a new random quote for the user")
    
    func perform() async throws -> some IntentResult {
        guard SupabaseManager.shared.isUserAuthenticated() else {
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result(dialog: "Please sign in to the app to get your daily quotes")
        }
        
        // Mirror exactly what the app does - just assign a new quote
        do {
            _ = try await SupabaseManager.shared.assignRandomQuoteToUser()
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result()
        } catch {
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result(dialog: "Failed to get new quote. Please try again.")
        }
    }
}
