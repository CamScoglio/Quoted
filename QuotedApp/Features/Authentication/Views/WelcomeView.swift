//
//  WelcomeView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showPhoneAuth = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo/Icon
                    VStack(spacing: 20) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Quoted")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Daily inspiration at your fingertips")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Authentication Options
                    VStack(spacing: 16) {
                        // Phone Authentication Button
                        Button(action: {
                            showPhoneAuth = true
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Continue with Phone")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        
                        // Anonymous Continue Button
                        Button(action: {
                            Task {
                                do {
                                    _ = try await userManager.signInAnonymously()
                                } catch {
                                    print("❌ Anonymous sign in failed: \(error)")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.fill.questionmark")
                                Text("Continue as Guest")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Benefits Text
                    VStack(spacing: 8) {
                        Text("Why create an account?")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BenefitRow(icon: "icloud.fill", text: "Sync across all your devices")
                            BenefitRow(icon: "heart.fill", text: "Save your favorite quotes")
                            BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your reading streak")
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView()
                .environmentObject(userManager)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(UserManager.shared)
} 