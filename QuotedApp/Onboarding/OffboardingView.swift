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
            VStack(spacing: AppLayout.spacingXLarge) {
                Spacer()
                
                // Success animation/icon with modern styling
                VStack(spacing: AppLayout.spacingLarge) {
                    // Success checkmark with modern gradient
                    SuccessCheckmark()
                    
                    // Success message with clean text (no card)
                    VStack(spacing: AppLayout.spacingMedium) {
                        Text("You're all set!")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Welcome to Quoted! Get ready to discover daily inspiration through beautiful, curated quotes.")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .cleanTextSection()
                }
                
                Spacer()
                
                // Get started button with modern styling
                VStack(spacing: AppLayout.spacingMedium) {
                    Button {
                        print("🟢 [OffboardingView] Get Started button tapped")
                        navigateToMainApp = true
                    } label: {
                        HStack {
                            Text("Get Started")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .primaryButton()
                    
                    // Optional subtitle with modern typography
                    Text("Start exploring your daily quotes")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.horizontal, AppLayout.paddingLarge)
                .padding(.bottom, 50)
            }
            .modernBackground()
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