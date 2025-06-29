//
//  AnalyticsManager.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

// MARK: - Simple Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let supabase = SupabaseManager.shared.client
    private let userManager = UserManager.shared
    
    private init() {}
    
    // MARK: - Basic Tracking (Optional)
    
    func trackQuoteViewed(quote: DailyQuote) async {
        // Simple tracking - just log for now
        print("📖 Quote viewed: \(quote.quoteText.prefix(50))...")
    }
    
    func trackQuoteShared(quote: DailyQuote) async {
        // Simple tracking - just log for now  
        print("📤 Quote shared: \(quote.quoteText.prefix(50))...")
    }
    
    func trackAppOpened() async {
        // Simple tracking - just log for now
        print("🚀 App opened")
    }
    
    func trackWidgetInteraction() async {
        // Simple tracking - just log for now
        print("📱 Widget interaction")
    }
}

// MARK: - Analytics Models
struct QuoteAnalytics: Codable {
    let id: UUID
    let userId: UUID
    let quoteId: UUID
    let action: Action
    let timestamp: Date
    let metadata: [String: String]
    
    enum Action: String, Codable {
        case viewed = "viewed"
        case favorited = "favorited"
        case shared = "shared"
    }
}

struct AppAnalytics: Codable {
    let id: UUID
    let userId: UUID
    let event: Event
    let timestamp: Date
    let metadata: [String: String]
    
    enum Event: String, Codable {
        case appOpened = "app_opened"
        case widgetInteraction = "widget_interaction"
    }
}

struct UserAnalyticsSummary {
    let totalQuotesViewed: Int
    let totalQuotesFavorited: Int
    let totalQuotesShared: Int
    let totalAppOpens: Int
    let currentReadingStreak: Int
    let longestReadingStreak: Int
    let joinDate: Date
}

// MARK: - Analytics Errors
enum AnalyticsError: LocalizedError {
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found for analytics tracking."
        case .networkError:
            return "Network error occurred while tracking analytics."
        }
    }
} 