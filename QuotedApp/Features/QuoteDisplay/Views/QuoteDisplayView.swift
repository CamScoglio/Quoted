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
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 0.5)
                )
            
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
            
            // Quote date (optional)
            if let date = quote.dateAssigned {
                Text("Quote for \(date, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

#Preview {
    let sampleQuote = DailyQuote(
        id: UUID(),
        quoteText: "The only way to do great work is to love what you do.",
        authors: Author(id: UUID(), name: "Steve Jobs", bio: nil, birthYear: nil, deathYear: nil),
        categories: Category(id: UUID(), name: "Motivation", description: nil),
        dateAssigned: Date(),
        backgroundGradient: ["start": "4F46E5", "end": "7C3AED"]
    )
    
    QuoteDisplayView(quote: sampleQuote)
        .background(
            LinearGradient(
                colors: [Color(hex: "4F46E5"), Color(hex: "7C3AED")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
} 