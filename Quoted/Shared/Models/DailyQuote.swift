//
//  DailyQuote.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

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