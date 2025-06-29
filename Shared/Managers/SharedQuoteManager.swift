//
//  SharedQuoteManager.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

// MARK: - Shared Quote Manager
// Handles quote consistency between widget and main app using user-centric system
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
    
    // Save the current quote to Supabase backend using new user_daily_quotes system
    func saveCurrentQuote(_ quote: DailyQuote) async {
        do {
            let currentTime = ISO8601DateFormatter().string(from: Date())
            print("🔍 SharedQuoteManager: Attempting to save quote \(quote.id.uuidString) for device \(deviceId)")
            
            // Get current user ID if authenticated, otherwise use device ID
            let userId = await UserManager.shared.currentUser?.id
            
            // First, try to update existing daily quote assignment
            let updateResult = try await supabase
                .from("user_daily_quotes")
                .update([
                    "is_viewed": true,
                    "viewed_at": currentTime
                ])
                .eq("quote_id", value: quote.id.uuidString)
                .eq(userId != nil ? "user_id" : "device_id", value: userId?.uuidString ?? deviceId)
                .eq("assigned_date", value: ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date())))
                .execute()
            
            print("🔍 SharedQuoteManager: Update result count: \(updateResult.count ?? -1)")
            
            // If no rows were updated, create a new daily quote assignment
            if (updateResult.count ?? 0) == 0 {
                print("🔍 SharedQuoteManager: No existing assignment found, creating new one")
                
                var insertData: [String: Any] = [
                    "quote_id": quote.id.uuidString,
                    "assigned_date": ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date())),
                    "is_viewed": true,
                    "viewed_at": currentTime
                ]
                
                if let userId = userId {
                    insertData["user_id"] = userId.uuidString
                } else {
                    insertData["device_id"] = deviceId
                }
                
                try await supabase
                    .from("user_daily_quotes")
                    .insert(insertData)
                    .execute()
                
                print("🔍 SharedQuoteManager: Created new daily quote assignment")
            } else {
                print("🔍 SharedQuoteManager: Updated existing assignment")
            }
            
            print("📝 SharedQuoteManager: Successfully saved quote to backend - \"\(quote.quoteText.prefix(50))...\"")
        } catch {
            print("❌ SharedQuoteManager: Failed to save quote to backend - \(error)")
            print("❌ SharedQuoteManager: Error details: \(String(describing: error))")
            // Fallback to local storage
            saveCurrentQuoteLocally(quote)
        }
    }
    
    // Get the current shared quote from Supabase using new system
    func getCurrentQuote() async -> DailyQuote? {
        do {
            let userId = await UserManager.shared.currentUser?.id
            let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
            
            // Get today's assigned quote for this user/device
            let response = try await supabase
                .from("user_daily_quotes")
                .select("""
                    quote_id,
                    assigned_date,
                    is_viewed,
                    quotes!inner(
                        id,
                        quote_text,
                        source,
                        tags,
                        background_gradient,
                        authors!inner(
                            id,
                            name,
                            bio,
                            birth_year,
                            death_year
                        ),
                        categories!inner(
                            id,
                            name,
                            description,
                            color_hex
                        )
                    )
                """)
                .eq(userId != nil ? "user_id" : "device_id", value: userId?.uuidString ?? deviceId)
                .eq("assigned_date", value: today)
                .execute()
            
            // Parse the response manually since we're dealing with joined data
            if let data = response.data,
               let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstItem = jsonArray.first,
               let quotesData = firstItem["quotes"] as? [String: Any] {
                
                // Convert the nested quote data back to DailyQuote
                let quoteJson = try JSONSerialization.data(withJSONObject: quotesData)
                let quote = try JSONDecoder().decode(DailyQuote.self, from: quoteJson)
                
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
            let userId = await UserManager.shared.currentUser?.id
            let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
            
            let response = try await supabase
                .from("user_daily_quotes")
                .select("assigned_date, viewed_at")
                .eq(userId != nil ? "user_id" : "device_id", value: userId?.uuidString ?? deviceId)
                .eq("assigned_date", value: today)
                .execute()
            
            if let data = response.data,
               let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstItem = jsonArray.first,
               let viewedAtString = firstItem["viewed_at"] as? String,
               let viewedAt = ISO8601DateFormatter().date(from: viewedAtString) {
                
                let timeSinceUpdate = Date().timeIntervalSince(viewedAt)
                return timeSinceUpdate > maxAge
            } else {
                return true // No previous update, should fetch
            }
        } catch {
            print("❌ SharedQuoteManager: Failed to check update time - \(error)")
            return true // On error, fetch new quote
        }
    }
    
    // Clear the shared quote from backend and local storage
    func clearCurrentQuote() async {
        do {
            let userId = await UserManager.shared.currentUser?.id
            let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
            
            try await supabase
                .from("user_daily_quotes")
                .delete()
                .eq(userId != nil ? "user_id" : "device_id", value: userId?.uuidString ?? deviceId)
                .eq("assigned_date", value: today)
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