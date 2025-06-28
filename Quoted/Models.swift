//
//  Models.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import WidgetKit
import AppIntents

struct Quote: Codable, Identifiable {
    let id: UUID
    let quoteText: String
    let authorId: UUID
    let categoryId: UUID
    let designTheme: String
    let backgroundGradient: [String: String]?
    let isFeatured: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, authorId = "author_id", categoryId = "category_id"
        case quoteText = "quote_text", designTheme = "design_theme"
        case backgroundGradient = "background_gradient"
        case isFeatured = "is_featured", createdAt = "created_at"
    }
}

struct Author: Codable, Identifiable {
    let id: UUID
    let name: String
    let profession: String
    let bio: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, profession, bio
        case imageUrl = "image_url"
    }
}

struct DailyQuote: Codable {
    // Quote fields (flattened)
    let id: UUID
    let quoteText: String
    let authorId: UUID
    let categoryId: UUID
    let designTheme: String
    let backgroundGradient: [String: String]?
    let isFeatured: Bool
    let createdAt: Date
    
    // Related objects
    let authors: Author
    let categories: Category
    
    enum CodingKeys: String, CodingKey {
        case id, authorId = "author_id", categoryId = "category_id"
        case quoteText = "quote_text", designTheme = "design_theme"
        case backgroundGradient = "background_gradient"
        case isFeatured = "is_featured", createdAt = "created_at"
        case authors, categories
    }
    
    // Computed properties to match the old API
    var quote: Quote {
        Quote(
            id: id,
            quoteText: quoteText,
            authorId: authorId,
            categoryId: categoryId,
            designTheme: designTheme,
            backgroundGradient: backgroundGradient,
            isFeatured: isFeatured,
            createdAt: createdAt
        )
    }
    
    var author: Author {
        authors
    }
    
    var category: Category {
        categories
    }
}

struct Category: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String?
    let themeColor: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case themeColor = "theme_color"
        case createdAt = "created_at"
    }
}

// MARK: - App Intents
struct NextQuoteIntent: AppIntent {
    static var title: LocalizedStringResource { "Next Quote" }
    static var description: IntentDescription { "Get the next random quote" }
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        print("🔵 NextQuoteIntent: Button was tapped!")
        print("🔵 NextQuoteIntent: About to clear shared quote and reload widget timeline...")
        
        // Clear the current shared quote so widget fetches a new one
        SharedQuoteManager.shared.clearCurrentQuote()
        
        // Reload all widgets of this kind to fetch a new random quote
        WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
        
        print("🔵 NextQuoteIntent: Widget timeline reload requested")
        print("🔵 NextQuoteIntent: Intent completed successfully")
        
        return .result()
    }
}

