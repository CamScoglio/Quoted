//
//  ContentView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var quoteService = QuoteService()
    @State private var currentQuote: DailyQuote?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                if let quote = currentQuote,
                   let gradient = quote.backgroundGradient,
                   let startColor = gradient["start"],
                   let endColor = gradient["end"] {
                    LinearGradient(
                        colors: [Color(hex: startColor), Color(hex: endColor)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 30) {
                    if isLoading {
                        ProgressView("Loading quote...")
                            .foregroundColor(.white)
                    } else if let quote = currentQuote {
                        QuoteDisplayView(quote: quote)
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Refresh button
                    Button(action: loadRandomQuote) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New Quote")
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Quoted")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadTodaysQuote()
        }
    }
    
    private func loadTodaysQuote() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to get shared quote first for consistency
            if let sharedQuote = await quoteService.getCurrentSharedQuote() {
                currentQuote = sharedQuote
                print("🔄 ContentView: Loaded shared quote for consistency")
            } else {
                currentQuote = try await quoteService.getTodaysQuote()
                print("🆕 ContentView: Loaded fresh today's quote")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadRandomQuote() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                currentQuote = try await quoteService.fetchNewQuote()
                print("🎲 ContentView: Loaded new random quote")
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

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

#Preview {
    ContentView()
}
