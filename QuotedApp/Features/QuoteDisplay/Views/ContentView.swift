//
//  ContentView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var currentQuote: DailyQuote?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private let supabase = SupabaseService.shared
    
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
                        ProgressView("Loading your daily quote...")
                            .foregroundColor(.white)
                    } else if let quote = currentQuote {
                        QuoteDisplayView(quote: quote)
                    } else if let error = errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(error)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        // New quote button
                        Button(action: { Task { await loadNewQuote() } }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("New Quote")
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
            }
            .navigationTitle("Quoted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        Task { 
                            print("🔄 [ContentView] User signing out - clearing onboarding flag")
                            hasCompletedOnboarding = false
                            await supabase.signOut() 
                        }
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .task {
            await loadDailyQuote()
        }
    }
    
    private func loadDailyQuote() async {
        isLoading = true
        errorMessage = nil
        
        // Retry logic to handle race condition with authentication
        var retryCount = 0
        let maxRetries = 3
        let retryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds
        
        while retryCount < maxRetries {
            do {
                // Try to get the user's daily quote
                if let existingQuote = try await supabase.getUserDailyQuote() {
                    currentQuote = existingQuote
                    isLoading = false
                    return
                } else {
                    // No row exists yet - this might be a race condition with authentication
                    if retryCount < maxRetries - 1 {
                        print("📝 [ContentView] No user_daily_quotes row found - retrying in 1 second (attempt \(retryCount + 1)/\(maxRetries))")
                        retryCount += 1
                        do {
                            try await Task.sleep(nanoseconds: retryDelay)
                        } catch {
                            print("📝 [ContentView] Sleep interrupted: \(error)")
                        }
                        continue
                    } else {
                        // Final attempt failed - show error
                        errorMessage = "No daily quote found. Please try refreshing or contact support."
                        currentQuote = nil
                    }
                }
            } catch {
                if retryCount < maxRetries - 1 {
                    print("📝 [ContentView] Error loading quote - retrying in 1 second (attempt \(retryCount + 1)/\(maxRetries)): \(error)")
                    retryCount += 1
                    do {
                        try await Task.sleep(nanoseconds: retryDelay)
                    } catch {
                        print("📝 [ContentView] Sleep interrupted: \(error)")
                    }
                    continue
                } else {
                    // Final attempt failed - show error
                    errorMessage = error.localizedDescription
                }
            }
            break
        }
        
        isLoading = false
    }
    
    private func loadNewQuote() async {
        print("🎲 [ContentView] loadNewQuote() called - User pressed New Quote button")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🎲 [ContentView] Calling assignRandomQuoteToUser()...")
            let newQuote = try await supabase.assignRandomQuoteToUser()
            print("🎲 [ContentView] ✅ Received new quote: '\(newQuote.quoteText)' by \(newQuote.authors.name)")
            
            // Update the UI
            currentQuote = newQuote
            print("🎲 [ContentView] ✅ UI updated with new quote")
            
            // Also force widget reload after new quote
            // CRITICAL: Add small delay to ensure UserDefaults sync completed
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            print("🎲 [ContentView] Forcing widget reload after new quote assignment")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            
        } catch {
            print("🔴 [ContentView] Error in loadNewQuote: \(error)")
            errorMessage = error.localizedDescription
        }
        
        print("🎲 [ContentView] loadNewQuote() completed, isLoading = false")
        isLoading = false
    }
    
    /// Start polling for widget-triggered updates
    private func startSyncPolling() async {
        print("🔄 [ContentView] Starting sync polling...")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.Scoglio.Quoted")
        
        while !Task.isCancelled {
            // Check if widget triggered a general sync
            if supabase.needsSync() {
                print("🔄 [ContentView] ✅ General sync needed - reloading quote from database")
                await loadDailyQuote()
            }
            
            // Check if widget needs data
            if sharedDefaults?.bool(forKey: "widgetNeedsData") == true {
                print("🔄 [ContentView] ✅ Widget needs data - ensuring quote is available")
                sharedDefaults?.set(false, forKey: "widgetNeedsData")
                
                if currentQuote == nil {
                    await loadDailyQuote()
                } else {
                    // Just refresh the shared storage with current quote
                    if let quote = currentQuote {
                        supabase.saveQuoteToSharedStorage(quote)
                        print("🔄 [ContentView] Refreshed shared storage with current quote")
                    }
                }
                
                // CRITICAL: Ensure data changes are written to disk before widget reload
                sharedDefaults?.synchronize()
                
                // Force widget reload after providing data
                WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            }
            
            // Check every 2 seconds for sync needs
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        print("🔄 [ContentView] Sync polling stopped")
    }
}

#Preview {
    ContentView()
} 
