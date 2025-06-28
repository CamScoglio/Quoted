//
//  QuoteService.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

// MARK: - Shared Quote Manager
// Handles quote consistency between widget and main app using Supabase backend
class SharedQuoteManager {
    static let shared = SharedQuoteManager()
    
    private let supabase = SupabaseManager.shared.client
    private let deviceId: String
    
    private init() {
        // Generate a unique device ID that persists across app launches
        if let existingId = UserDefaults.standard.string(forKey: "device_id") {
            self.deviceId = existingId
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: "device_id")
        }
        print("🔧 SharedQuoteManager: Using device ID - \(deviceId)")
    }
    
    // Save the current quote to Supabase backend
    func saveCurrentQuote(_ quote: DailyQuote) async {
        do {
            let currentTime = ISO8601DateFormatter().string(from: Date())
            
            // First, try to update existing session
            let updateResult = try await supabase
                .from("user_sessions")
                .update([
                    "current_quote_id": quote.id.uuidString,
                    "last_updated": currentTime
                ])
                .eq("device_id", value: deviceId)
                .execute()
            
            // If no rows were updated, create a new session
            if updateResult.count == 0 {
                let _: [UserSession] = try await supabase
                    .from("user_sessions")
                    .insert([
                        "device_id": deviceId,
                        "current_quote_id": quote.id.uuidString
                    ])
                    .execute()
                    .value
            }
            
            print("📝 SharedQuoteManager: Saved quote to backend - \"\(quote.quoteText.prefix(50))...\"")
        } catch {
            print("❌ SharedQuoteManager: Failed to save quote to backend - \(error)")
            // Fallback to local storage
            saveCurrentQuoteLocally(quote)
        }
    }
    
    // Get the current shared quote from Supabase
    func getCurrentQuote() async -> DailyQuote? {
        do {
            // Get the user session for this device
            let sessions: [UserSessionWithQuote] = try await supabase
                .from("user_sessions")
                .select("""
                    current_quote_id,
                    last_updated,
                    quotes!inner(*,
                        authors!inner(*),
                        categories!inner(*)
                    )
                """)
                .eq("device_id", value: deviceId)
                .execute()
                .value
            
            if let session = sessions.first,
               let quote = session.quotes {
                print("📖 SharedQuoteManager: Retrieved quote from backend - \"\(quote.quoteText.prefix(50))...\"")
                
                // Also save locally as cache
                saveCurrentQuoteLocally(quote)
                return quote
            } else {
                print("📖 SharedQuoteManager: No shared quote found in backend")
                return getCurrentQuoteLocally()
            }
        } catch {
            print("❌ SharedQuoteManager: Failed to get quote from backend - \(error)")
            // Fallback to local storage
            return getCurrentQuoteLocally()
        }
    }
    
    // Check if we should fetch a new quote (optional: time-based refresh)
    func shouldFetchNewQuote(maxAge: TimeInterval = 3600) async -> Bool { // 1 hour default
        do {
            let sessions: [UserSession] = try await supabase
                .from("user_sessions")
                .select("last_updated")
                .eq("device_id", value: deviceId)
                .execute()
                .value
            
            guard let session = sessions.first,
                  let lastUpdateString = session.lastUpdated,
                  let lastUpdate = ISO8601DateFormatter().date(from: lastUpdateString) else {
                return true // No previous update, should fetch
            }
            
            let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
            return timeSinceUpdate > maxAge
        } catch {
            print("❌ SharedQuoteManager: Failed to check update time - \(error)")
            return true // On error, fetch new quote
        }
    }
    
    // Clear the shared quote from backend and local storage
    func clearCurrentQuote() async {
        do {
            try await supabase
                .from("user_sessions")
                .delete()
                .eq("device_id", value: deviceId)
                .execute()
            
            print("🗑️ SharedQuoteManager: Cleared shared quote from backend")
        } catch {
            print("❌ SharedQuoteManager: Failed to clear quote from backend - \(error)")
        }
        
        // Also clear local cache
        clearCurrentQuoteLocally()
    }
    
    // MARK: - Local Fallback Methods
    
    private func saveCurrentQuoteLocally(_ quote: DailyQuote) {
        do {
            let data = try JSONEncoder().encode(quote)
            UserDefaults.standard.set(data, forKey: "current_quote_local")
            UserDefaults.standard.set(Date(), forKey: "last_quote_update_local")
            print("📝 SharedQuoteManager: Saved quote locally as fallback")
        } catch {
            print("❌ SharedQuoteManager: Failed to save quote locally - \(error)")
        }
    }
    
    private func getCurrentQuoteLocally() -> DailyQuote? {
        guard let data = UserDefaults.standard.data(forKey: "current_quote_local") else {
            return nil
        }
        
        do {
            let quote = try JSONDecoder().decode(DailyQuote.self, from: data)
            print("📖 SharedQuoteManager: Retrieved quote from local fallback")
            return quote
        } catch {
            print("❌ SharedQuoteManager: Failed to decode local quote - \(error)")
            return nil
        }
    }
    
    private func clearCurrentQuoteLocally() {
        UserDefaults.standard.removeObject(forKey: "current_quote_local")
        UserDefaults.standard.removeObject(forKey: "last_quote_update_local")
        print("🗑️ SharedQuoteManager: Cleared local quote cache")
    }
}

class QuoteService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    private let sharedManager = SharedQuoteManager.shared
    
    func getTodaysQuote() async throws -> DailyQuote {
        // First, try to get the shared quote if it's recent enough
        if let sharedQuote = await sharedManager.getCurrentQuote(),
           !(await sharedManager.shouldFetchNewQuote()) {
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
        await sharedManager.saveCurrentQuote(quote)
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
        await sharedManager.saveCurrentQuote(randomQuote)
        return randomQuote
    }
    
    // Get the current shared quote without fetching new one
    func getCurrentSharedQuote() async -> DailyQuote? {
        return await sharedManager.getCurrentQuote()
    }
    
    // Force fetch a new quote and update shared storage
    func fetchNewQuote() async throws -> DailyQuote {
        let quote = try await getRandomQuote()
        await sharedManager.saveCurrentQuote(quote)
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
