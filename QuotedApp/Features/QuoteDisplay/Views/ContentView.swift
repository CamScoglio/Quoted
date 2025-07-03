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
        NavigationStack {
            GeometryReader { geometry in
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
                    
                    // Responsive content container
                    VStack(spacing: responsiveSpacing(for: geometry.size)) {
                    if isLoading {
                        ProgressView("Loading your daily quote...")
                            .foregroundColor(AppColors.adaptiveOverlayText)
                    } else if let quote = currentQuote {
                        QuoteDisplayView(quote: quote)
                    } else if let error = errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.adaptiveOverlayTextSecondary)
                            
                            Text("Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.adaptiveOverlayText)
                            
                            Text(error)
                                .foregroundColor(AppColors.adaptiveOverlayTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: responsiveButtonSpacing(for: geometry.size)) {
                        // New quote button
                        Button(action: { Task { await loadNewQuote() } }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(responsiveButtonIconFont(for: geometry.size))
                                Text("New Quote")
                                    .font(responsiveButtonFont(for: geometry.size))
                            }
                            .padding(responsiveButtonPadding(for: geometry.size))
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(AppColors.adaptiveOverlayText)
                            .cornerRadius(responsiveButtonCornerRadius(for: geometry.size))
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(responsivePadding(for: geometry.size))
                .frame(maxWidth: maxContentWidth(for: geometry.size), alignment: .center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
                    .foregroundColor(AppColors.adaptiveOverlayText)
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
    
    // MARK: - Responsive Layout Helpers
    
    /// Calculate responsive spacing based on screen size
    private func responsiveSpacing(for size: CGSize) -> CGFloat {
        let baseSpacing: CGFloat = 30
        let scaleFactor = min(size.width / 390, size.height / 844) // iPhone 12 Pro as base
        return max(baseSpacing * scaleFactor, 20) // Minimum 20pt spacing
    }
    
    /// Calculate responsive padding based on screen size
    private func responsivePadding(for size: CGSize) -> CGFloat {
        let basePadding: CGFloat = 16
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(basePadding * scaleFactor, 12) // Minimum 12pt padding
    }
    
    /// Calculate maximum content width for better readability on large screens
    private func maxContentWidth(for size: CGSize) -> CGFloat {
        // On Mac, limit content width for better readability
        #if targetEnvironment(macCatalyst)
        return min(size.width * 0.7, 600) // Max 600pt wide or 70% of screen
        #else
        return size.width // Full width on iOS
        #endif
    }
    
    // MARK: - Button Responsive Helpers
    
    private func responsiveButtonSpacing(for size: CGSize) -> CGFloat {
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(20 * scaleFactor, 15)
    }
    
    private func responsiveButtonPadding(for size: CGSize) -> CGFloat {
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(16 * scaleFactor, 12)
    }
    
    private func responsiveButtonFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 390, size.height / 844)
        
        #if targetEnvironment(macCatalyst)
        if scaleFactor > 1.5 {
            return .title3
        } else if scaleFactor > 1.2 {
            return .headline
        }
        #endif
        
        return .headline
    }
    
    private func responsiveButtonIconFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 390, size.height / 844)
        
        #if targetEnvironment(macCatalyst)
        if scaleFactor > 1.5 {
            return .title3
        } else if scaleFactor > 1.2 {
            return .headline
        }
        #endif
        
        return .headline
    }
    
    private func responsiveButtonCornerRadius(for size: CGSize) -> CGFloat {
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(10 * scaleFactor, 8)
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
