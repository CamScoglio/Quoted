//
//  QuoteService.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

// MARK: - Shared Quote Manager
// Handles quote consistency between widget and main app
class SharedQuoteManager {
    static let shared = SharedQuoteManager()
    
    private let userDefaults = UserDefaults.standard  // Using standard defaults until App Groups is configured
    private let currentQuoteKey = "current_quote"
    private let lastUpdateKey = "last_quote_update"
    
    private init() {}
    
    // Save the current quote to shared storage
    func saveCurrentQuote(_ quote: DailyQuote) {
        do {
            let data = try JSONEncoder().encode(quote)
            userDefaults.set(data, forKey: currentQuoteKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
            print("📝 SharedQuoteManager: Saved quote - \"\(quote.quoteText.prefix(50))...\"")
        } catch {
            print("❌ SharedQuoteManager: Failed to save quote - \(error)")
        }
    }
    
    // Get the current shared quote
    func getCurrentQuote() -> DailyQuote? {
        guard let data = userDefaults.data(forKey: currentQuoteKey) else {
            print("📖 SharedQuoteManager: No shared quote found")
            return nil
        }
        
        do {
            let quote = try JSONDecoder().decode(DailyQuote.self, from: data)
            print("📖 SharedQuoteManager: Retrieved quote - \"\(quote.quoteText.prefix(50))...\"")
            return quote
        } catch {
            print("❌ SharedQuoteManager: Failed to decode quote - \(error)")
            return nil
        }
    }
    
    // Check if we should fetch a new quote (optional: time-based refresh)
    func shouldFetchNewQuote(maxAge: TimeInterval = 3600) -> Bool { // 1 hour default
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date else {
            return true // No previous update, should fetch
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceUpdate > maxAge
    }
    
    // Clear the shared quote (useful for testing or reset)
    func clearCurrentQuote() {
        userDefaults.removeObject(forKey: currentQuoteKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
        print("🗑️ SharedQuoteManager: Cleared shared quote")
    }
}

class QuoteService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    private let sharedManager = SharedQuoteManager.shared
    
    func getTodaysQuote() async throws -> DailyQuote {
        // First, try to get the shared quote if it's recent enough
        if let sharedQuote = sharedManager.getCurrentQuote(),
           !sharedManager.shouldFetchNewQuote() {
            print("🔄 QuoteService: Using shared quote for consistency")
            return sharedQuote
        }
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        
        // Get today's featured quote with joins
        let response: [DailyQuote] = try await supabase
            .from("daily_features")
            .select("""
                quotes!inner(*,
                 authors!inner(*),
                categories!inner(*)
                )
            """)
            .eq("feature_date", value: today)
            .execute()
            .value
        
        let quote: DailyQuote
        if let todaysQuote = response.first {
            quote = todaysQuote
        } else {
            // Fallback to random quote
            quote = try await getRandomQuote()
        }
        
        // Save the fetched quote for consistency
        sharedManager.saveCurrentQuote(quote)
        return quote
    }
    
    // Make this method public for widget use
    func getRandomQuote() async throws -> DailyQuote {
        // First, get the total count of quotes
        let countResponse = try await supabase
            .from("quotes")
            .select("id", head: true, count: .exact)
            .execute()
        
        guard let totalCount = countResponse.count, totalCount > 0 else {
            throw QuoteServiceError.noQuotesFound
        }
        
        // Generate a random offset
        let randomOffset = Int.random(in: 0..<totalCount)
        
        // Get a quote with the random offset - use same structure as getTodaysQuote
        let response: [DailyQuote] = try await supabase
            .from("quotes")
            .select("""
                *,
                authors!inner(*),
                categories!inner(*)
            """)
            .range(from: randomOffset, to: randomOffset)
            .execute()
            .value
        
        guard let randomQuote = response.first else {
            throw QuoteServiceError.noQuotesFound
        }
        
        // Save the new random quote for consistency
        sharedManager.saveCurrentQuote(randomQuote)
        return randomQuote
    }
    
    // Get the current shared quote without fetching new one
    func getCurrentSharedQuote() -> DailyQuote? {
        return sharedManager.getCurrentQuote()
    }
    
    // Force fetch a new quote and update shared storage
    func fetchNewQuote() async throws -> DailyQuote {
        let quote = try await getRandomQuote()
        sharedManager.saveCurrentQuote(quote)
        return quote
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

enum QuoteServiceError: Error {
    case noQuotesFound
    case networkError
}
