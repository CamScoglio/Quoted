//
//  QuoteDisplayView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct QuoteDisplayView: View {
    let quote: DailyQuote
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var analyticsManager: AnalyticsManager
    @State private var isFavorited = false
    @State private var showingFavoriteAnimation = false
    
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
            
            // Category and Favorite
            HStack(spacing: 16) {
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
                
                Spacer()
                
                // Favorite button (only for authenticated users)
                if userManager.currentUser?.isAnonymous == false {
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(isFavorited ? .red : .white.opacity(0.8))
                            .scaleEffect(showingFavoriteAnimation ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingFavoriteAnimation)
                    }
                }
            }
            
            // Quote metadata (for debugging/info)
            if let date = quote.dateAssigned {
                Text("Quote for \(date, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onAppear {
            checkIfFavorited()
        }
    }
    
    private func toggleFavorite() {
        guard userManager.currentUser?.isAnonymous == false else { return }
        
        isFavorited.toggle()
        showingFavoriteAnimation = true
        
        // Reset animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingFavoriteAnimation = false
        }
        
        // Track analytics
        Task {
            if isFavorited {
                await analyticsManager.trackQuoteFavorited(quote: quote)
            } else {
                await analyticsManager.trackQuoteUnfavorited(quote: quote)
            }
        }
        
        // TODO: Save favorite status to database
        // This would be implemented when we add the favorites feature to the database
    }
    
    private func checkIfFavorited() {
        // TODO: Check if quote is favorited from database
        // For now, we'll keep it simple
        isFavorited = false
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
        .environmentObject(UserManager.shared)
        .environmentObject(AnalyticsManager.shared)
        .background(
            LinearGradient(
                colors: [Color(hex: "4F46E5"), Color(hex: "7C3AED")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
} 