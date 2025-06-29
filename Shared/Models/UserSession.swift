//
//  UserSession.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

// MARK: - User Session Models
struct UserSession: Codable {
    let id: UUID
    let deviceId: String
    let currentQuoteId: UUID?
    let lastUpdated: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case currentQuoteId = "current_quote_id"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}

struct UserSessionWithQuote: Codable {
    let currentQuoteId: UUID?
    let lastUpdated: String?
    let quotes: DailyQuote?
    
    enum CodingKeys: String, CodingKey {
        case currentQuoteId = "current_quote_id"
        case lastUpdated = "last_updated"
        case quotes
    }
} 