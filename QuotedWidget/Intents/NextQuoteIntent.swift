//
//  NextQuoteIntent.swift
//  QuotedWidgetExtension
//
//  Created by Cam Scoglio on 6/25/25.
//

import AppIntents
import WidgetKit

struct NextQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Quote"
    static var description = IntentDescription("Get a new random quote for the user")
    
    private let supabase = SupabaseManager.shared
    
    func perform() async throws -> some IntentResult {
        // Check authentication by trying to get current user
        guard let currentUser = await supabase.getCurrentUser() else {
            print("🔴 [NextQuoteIntent] User not authenticated")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result(dialog: "Please sign in to the app to get your daily quotes")
        }
        
        print("🟢 [NextQuoteIntent] User authenticated: \(currentUser.id)")
        
        do {
            // Assign a new quote to the authenticated user
            let newQuote = try await supabase.assignRandomQuoteToUser()
            print("🟢 [NextQuoteIntent] ✅ Successfully assigned new quote: '\(newQuote.quoteText)'")
            
            // Reload widget timelines to show the new quote
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            
            return .result(dialog: "New quote assigned! '\(newQuote.quoteText)' by \(newQuote.authors.name)")
            
        } catch {
            print("🔴 [NextQuoteIntent] Error assigning new quote: \(error)")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            return .result(dialog: "Failed to get new quote. Please try again.")
        }
    }
} 