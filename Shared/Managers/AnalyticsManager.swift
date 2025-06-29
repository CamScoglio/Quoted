import Foundation
import Supabase

// MARK: - Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let supabase = SupabaseManager.shared.client
    private let userManager = UserManager.shared
    
    private init() {}
    
    // MARK: - Quote Analytics
    
    func trackQuoteViewed(quote: DailyQuote) async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            let analytics = QuoteAnalytics(
                id: UUID(),
                userId: userId,
                quoteId: quote.id,
                action: .viewed,
                timestamp: Date(),
                metadata: [
                    "author": quote.authors.name,
                    "category": quote.categories.name
                ]
            )
            
            try await supabase
                .from("quote_analytics")
                .insert(analytics)
                .execute()
            
            print("📊 Analytics: Quote viewed - \(quote.quoteText.prefix(50))...")
        } catch {
            print("❌ Analytics Error: Failed to track quote view - \(error)")
        }
    }
    
    func trackQuoteFavorited(quote: DailyQuote) async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            let analytics = QuoteAnalytics(
                id: UUID(),
                userId: userId,
                quoteId: quote.id,
                action: .favorited,
                timestamp: Date(),
                metadata: [
                    "author": quote.authors.name,
                    "category": quote.categories.name
                ]
            )
            
            try await supabase
                .from("quote_analytics")
                .insert(analytics)
                .execute()
            
            print("📊 Analytics: Quote favorited - \(quote.quoteText.prefix(50))...")
        } catch {
            print("❌ Analytics Error: Failed to track quote favorite - \(error)")
        }
    }
    
    func trackQuoteShared(quote: DailyQuote, platform: String = "share_sheet") async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            let analytics = QuoteAnalytics(
                id: UUID(),
                userId: userId,
                quoteId: quote.id,
                action: .shared,
                timestamp: Date(),
                metadata: [
                    "author": quote.authors.name,
                    "category": quote.categories.name,
                    "platform": platform
                ]
            )
            
            try await supabase
                .from("quote_analytics")
                .insert(analytics)
                .execute()
            
            print("📊 Analytics: Quote shared on \(platform) - \(quote.quoteText.prefix(50))...")
        } catch {
            print("❌ Analytics Error: Failed to track quote share - \(error)")
        }
    }
    
    // MARK: - Reading Streak Analytics
    
    func updateReadingStreak() async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            // Get current streak data
            let today = Calendar.current.startOfDay(for: Date())
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            
            let recentReads: [QuoteAnalytics] = try await supabase
                .from("quote_analytics")
                .select()
                .eq("user_id", value: userId)
                .eq("action", value: QuoteAnalytics.Action.viewed.rawValue)
                .gte("timestamp", value: yesterday)
                .order("timestamp", ascending: false)
                .execute()
                .value
            
            let hasReadToday = recentReads.contains { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
            let hasReadYesterday = recentReads.contains { Calendar.current.isDate($0.timestamp, inSameDayAs: yesterday) }
            
            // Calculate new streak
            var newStreak = 1
            if hasReadToday && hasReadYesterday {
                // Continue existing streak
                let currentPrefs = userManager.currentUser?.preferences ?? .default
                newStreak = currentPrefs.readingStreak.currentStreak + 1
            } else if !hasReadToday {
                // Reset streak if haven't read today
                newStreak = 1
            }
            
            // Update user preferences with new streak
            let currentPrefs = userManager.currentUser?.preferences ?? .default
            let updatedStreak = UserPreferences.ReadingStreak(
                currentStreak: newStreak,
                longestStreak: max(newStreak, currentPrefs.readingStreak.longestStreak),
                lastReadDate: Date()
            )
            
            let updatedPrefs = UserPreferences(
                notificationTime: currentPrefs.notificationTime,
                preferredCategories: currentPrefs.preferredCategories,
                favoriteAuthors: currentPrefs.favoriteAuthors,
                themePreference: currentPrefs.themePreference,
                readingStreak: updatedStreak,
                privacySettings: currentPrefs.privacySettings
            )
            
            try await userManager.updatePreferences(updatedPrefs)
            
            print("📊 Analytics: Reading streak updated to \(newStreak) days")
        } catch {
            print("❌ Analytics Error: Failed to update reading streak - \(error)")
        }
    }
    
    // MARK: - User Engagement Analytics
    
    func trackAppOpened() async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            let analytics = AppAnalytics(
                id: UUID(),
                userId: userId,
                event: .appOpened,
                timestamp: Date(),
                metadata: [:]
            )
            
            try await supabase
                .from("app_analytics")
                .insert(analytics)
                .execute()
            
            print("📊 Analytics: App opened")
        } catch {
            print("❌ Analytics Error: Failed to track app open - \(error)")
        }
    }
    
    func trackWidgetInteraction(action: String) async {
        guard let userId = userManager.currentUser?.id else { return }
        
        do {
            let analytics = AppAnalytics(
                id: UUID(),
                userId: userId,
                event: .widgetInteraction,
                timestamp: Date(),
                metadata: ["action": action]
            )
            
            try await supabase
                .from("app_analytics")
                .insert(analytics)
                .execute()
            
            print("📊 Analytics: Widget interaction - \(action)")
        } catch {
            print("❌ Analytics Error: Failed to track widget interaction - \(error)")
        }
    }
    
    // MARK: - Analytics Retrieval
    
    func getUserAnalyticsSummary() async throws -> UserAnalyticsSummary {
        guard let userId = userManager.currentUser?.id else {
            throw AnalyticsError.userNotFound
        }
        
        // Get quote analytics
        let quoteAnalytics: [QuoteAnalytics] = try await supabase
            .from("quote_analytics")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Get app analytics
        let appAnalytics: [AppAnalytics] = try await supabase
            .from("app_analytics")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        // Calculate summary
        let totalQuotesViewed = quoteAnalytics.filter { $0.action == .viewed }.count
        let totalQuotesFavorited = quoteAnalytics.filter { $0.action == .favorited }.count
        let totalQuotesShared = quoteAnalytics.filter { $0.action == .shared }.count
        let totalAppOpens = appAnalytics.filter { $0.event == .appOpened }.count
        
        let currentStreak = userManager.currentUser?.preferences.readingStreak.currentStreak ?? 0
        let longestStreak = userManager.currentUser?.preferences.readingStreak.longestStreak ?? 0
        
        return UserAnalyticsSummary(
            totalQuotesViewed: totalQuotesViewed,
            totalQuotesFavorited: totalQuotesFavorited,
            totalQuotesShared: totalQuotesShared,
            totalAppOpens: totalAppOpens,
            currentReadingStreak: currentStreak,
            longestReadingStreak: longestStreak,
            joinDate: userManager.currentUser?.createdAt ?? Date()
        )
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