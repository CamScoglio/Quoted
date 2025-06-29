//
//  SharedQuoteManager.swift
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
            print("🔍 SharedQuoteManager: Attempting to save quote \(quote.id.uuidString) for device \(deviceId)")
            
            // First, try to update existing session
            let updateResult = try await supabase
                .from("user_sessions")
                .update([
                    "current_quote_id": quote.id.uuidString,
                    "last_updated": currentTime
                ])
                .eq("device_id", value: deviceId)
                .execute()
            
            print("🔍 SharedQuoteManager: Update result count: \(updateResult.count ?? -1)")
            
            // If no rows were updated (count is 0 or nil), create a new session
            if (updateResult.count ?? 0) == 0 {
                print("🔍 SharedQuoteManager: No existing session found, creating new one")
                let insertResult: [UserSession] = try await supabase
                    .from("user_sessions")
                    .insert([
                        "device_id": deviceId,
                        "current_quote_id": quote.id.uuidString
                    ])
                    .execute()
                    .value
                print("🔍 SharedQuoteManager: Insert result: \(insertResult.count) rows")
            } else {
                print("🔍 SharedQuoteManager: Updated existing session")
            }
            
            print("📝 SharedQuoteManager: Successfully saved quote to backend - \"\(quote.quoteText.prefix(50))...\"")
        } catch {
            print("❌ SharedQuoteManager: Failed to save quote to backend - \(error)")
            print("❌ SharedQuoteManager: Error details: \(String(describing: error))")
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