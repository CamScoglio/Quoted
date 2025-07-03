//
//  OffboardingView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import SwiftUI

struct OffboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppLayout.spacingXLarge) {
                Spacer()
                
                // Success animation/icon with modern styling
                VStack(spacing: AppLayout.spacinsgLarge) {
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
                        print("🟢 [OffboardingView] Setting hasCompletedOnboarding = true")
                        hasCompletedOnboarding = true
                        print("🟢 [OffboardingView] 🎉 ONBOARDING COMPLETE! AppView will now show ContentView")
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
            .onAppear {
                print("🟢 [OffboardingView] View appeared - User successfully authenticated!")
                print("🟢 [OffboardingView] Ready to complete onboarding flow")
            }
        }
    }
}

#Preview {
    OffboardingView()
}