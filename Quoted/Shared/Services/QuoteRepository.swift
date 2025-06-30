//
//  QuoteRepository.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import SwiftUI

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

// MARK: - Extensions and Utilities

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