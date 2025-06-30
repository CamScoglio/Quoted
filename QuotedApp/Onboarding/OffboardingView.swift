//
//  OffboardingView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import SwiftUI

struct OffboardingView: View {
    @State private var navigateToMainApp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 50) {
                Spacer()
                
                // Success animation/icon
                VStack(spacing: 30) {
                    // Success checkmark
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                    
                    // Success message
                    VStack(spacing: 16) {
                        Text("You're all set!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Welcome to Quoted! Get ready to discover daily inspiration through beautiful, curated quotes.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Get started button
                VStack(spacing: 16) {
                    Button(action: {
                        print("🟢 [OffboardingView] Get Started button tapped")
                        navigateToMainApp = true
                    }) {
                        HStack {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 32)
                    
                    // Optional subtitle
                    Text("Start exploring your daily quotes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToMainApp) {
                ContentView()
            }
            .onAppear {
                print("🟢 [OffboardingView] View appeared - Onboarding completed successfully!")
                print("🟢 [OffboardingView] User has finished the entire onboarding flow")
            }
            .onChange(of: navigateToMainApp) { _, newValue in
                if newValue {
                    print("🟢 [OffboardingView] Navigating to main app (ContentView)")
                    print("🟢 [OffboardingView] 🎉 ONBOARDING FLOW COMPLETE! 🎉")
                }
            }
        }
    }
}

#Preview {
    OffboardingView()
}