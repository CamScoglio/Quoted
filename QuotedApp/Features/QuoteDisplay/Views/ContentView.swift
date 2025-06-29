//
//  ContentView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var analyticsManager: AnalyticsManager
    @StateObject private var quoteRepository = QuoteRepository()
    @State private var currentQuote: DailyQuote?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingProfile = false
    
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
                            .environmentObject(userManager)
                            .environmentObject(analyticsManager)
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Oops! Something went wrong")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Try Again") {
                                loadTodaysQuote()
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
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
                        .disabled(isLoading)
                        
                        // Share button
                        if let quote = currentQuote {
                            ShareButton(quote: quote)
                                .environmentObject(analyticsManager)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quoted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: userManager.currentUser?.isAnonymous == true ? "person.circle" : "person.crop.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadTodaysQuote()
            // Track app usage
            await analyticsManager.trackAppOpened()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(userManager)
                .environmentObject(analyticsManager)
        }
    }
    
    private func loadTodaysQuote() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let quote = try await quoteRepository.getTodaysQuote()
                await MainActor.run {
                    currentQuote = quote
                    isLoading = false
                }
                
                // Track quote view
                await analyticsManager.trackQuoteViewed(quote: quote)
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func loadRandomQuote() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let quote = try await quoteRepository.fetchNewQuote()
                await MainActor.run {
                    currentQuote = quote
                    isLoading = false
                }
                
                // Track quote view
                await analyticsManager.trackQuoteViewed(quote: quote)
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ShareButton: View {
    let quote: DailyQuote
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        ShareLink(
            item: "\"\(quote.quoteText)\" - \(quote.authors.name)",
            subject: Text("Daily Quote from Quoted"),
            message: Text("Check out this inspiring quote!")
        ) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onTapGesture {
            Task {
                await analyticsManager.trackQuoteShared(quote: quote)
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var analyticsManager: AnalyticsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOut = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: userManager.currentUser?.isAnonymous == true ? "person.circle.fill" : "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        if let user = userManager.currentUser {
                            if user.isAnonymous {
                                Text("Guest User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Sign in to sync your data across devices")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(user.displayName ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Premium Member")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    // Reading Streak
                    if let user = userManager.currentUser,
                       let streak = user.preferences.readingStreak {
                        VStack(spacing: 8) {
                            Text("Reading Streak")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(streak.currentStreak)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                VStack {
                                    Text("\(streak.longestStreak)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Best")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        if userManager.currentUser?.isAnonymous == true {
                            Button("Sign In with Phone") {
                                // This would show the phone auth flow
                                dismiss()
                                // You could add logic here to show phone auth
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        
                        Button("Sign Out") {
                            showingSignOut = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await userManager.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager.shared)
        .environmentObject(AnalyticsManager.shared)
} 