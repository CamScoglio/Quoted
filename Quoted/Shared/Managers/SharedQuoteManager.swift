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
    
    // Save the current quote (TEMPORARY: Local storage only during transition)
    func saveCurrentQuote(_ quote: DailyQuote) async {
        print("⚠️ SharedQuoteManager: Using local storage during transition to user-based system")
        saveCurrentQuoteLocally(quote)
    }
    
    // Get the current shared quote (TEMPORARY: Local storage only during transition)
    func getCurrentQuote() async -> DailyQuote? {
        print("⚠️ SharedQuoteManager: Using local storage during transition to user-based system")
        return getCurrentQuoteLocally()
    }
    
    // Check if we should fetch a new quote (TEMPORARY: Check local storage during transition)
    func shouldFetchNewQuote(maxAge: TimeInterval = 3600) async -> Bool { // 1 hour default
        print("⚠️ SharedQuoteManager: Using local storage during transition to user-based system")
        
        guard let lastUpdate = UserDefaults.standard.object(forKey: "last_quote_update_local") as? Date else {
            return true // No previous update, should fetch
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceUpdate > maxAge
    }
    
    // Clear the shared quote (TEMPORARY: Local storage only during transition)
    func clearCurrentQuote() async {
        print("⚠️ SharedQuoteManager: Using local storage during transition to user-based system")
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
