//
//  NextQuoteIntent.swift
//  QuotedWidgetExtension
//
//  Created by Cam Scoglio on 6/25/25.
//

import AppIntents
import WidgetKit
import Foundation

struct NextQuoteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Next Quote"
    static var description = IntentDescription("Get a new random quote for the user")
    
    func perform() async throws -> some IntentResult {
        print("🟣 [Widget Intent] NextQuoteIntent triggered")
        
        // Check auth using shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.Scoglio.Quoted")
        let isAuth = sharedDefaults?.bool(forKey: "isAuthenticated") ?? false
        let userId = sharedDefaults?.string(forKey: "currentUserId")
        
        guard isAuth, userId != nil else {
            print("🔴 [Widget Intent] User not authenticated")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result()
        }
        
        print("🟣 [Widget Intent] User authenticated (ID: \(userId!)) - fetching new quote directly")
        
        // Use the shared SupabaseService instance
        do {
            // Fetch new quote directly
            print("🟣 [Widget Intent] Calling assignRandomQuoteToUser() directly...")
            let newQuote = try await SupabaseService.shared.assignRandomQuoteToUser()
            
            // Data is already saved to shared storage by assignRandomQuoteToUser()
            print("🟣 [Widget Intent] ✅ New quote assigned: '\(newQuote.quoteText)' by \(newQuote.authors.name)")
            
            // Force UserDefaults sync before timeline regeneration
            sharedDefaults?.synchronize()
            print("🟣 [Widget Intent] ✅ UserDefaults synchronized")
            
            // Force widget reload to show new quote immediately
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            print("🟣 [Widget Intent] ✅ Widget timeline reload triggered")
            
        } catch {
            print("🔴 [Widget Intent] Error fetching new quote: \(error)")
            // Fallback to flag-based approach
            sharedDefaults?.set(true, forKey: "widgetRequestsNewQuote")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "widgetRequestTimestamp")
            SupabaseService.shared.triggerSync()
            
            // Force widget reload to show error state
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
        }
        
        return .result()
    }
}
