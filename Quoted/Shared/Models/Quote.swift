//
//  Quote.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

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