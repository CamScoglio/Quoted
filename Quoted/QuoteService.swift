//
//  QuoteService.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

class QuoteService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    func getTodaysQuote() async throws -> DailyQuote {
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
        
        if let todaysQuote = response.first {
            return todaysQuote
        } else {
            // Fallback to random quote
            return try await getRandomQuote()
        }
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
        
        return randomQuote
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
