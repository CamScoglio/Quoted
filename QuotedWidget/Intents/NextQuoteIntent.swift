//
//  NextQuoteIntent.swift
//  QuotedWidget
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import WidgetKit
import AppIntents

// MARK: - App Intents
struct NextQuoteIntent: AppIntent {
    static var title: LocalizedStringResource { "Next Quote" }
    static var description: IntentDescription { "Get the next random quote" }
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        print("🔵 NextQuoteIntent: Button was tapped!")
        print("🔵 NextQuoteIntent: About to clear shared quote and reload widget timeline...")
        
        // Clear the current shared quote so widget fetches a new one
        await SharedQuoteManager.shared.clearCurrentQuote()
        
        // Reload all widgets of this kind to fetch a new random quote
        WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
        
        print("🔵 NextQuoteIntent: Widget timeline reload requested")
        print("🔵 NextQuoteIntent: Intent completed successfully")
        
        return .result()
    }
} 