//
//  QuoteDisplayView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct QuoteDisplayView: View {
    let quote: DailyQuote
    
    var body: some View {
        VStack(spacing: 20) {
            // Quote text
            Text(quote.quoteText)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            // Author
            Text("— \(quote.authors.name)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            // Category
            if !quote.categories.name.isEmpty {
                Text(quote.categories.name.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
} 