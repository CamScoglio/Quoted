//
//  StartingView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

//First thing a new user sees

//Onboarding starts

//Send to EmailView

import Foundation
import SwiftUI
import Supabase

struct StartingView: View {
    @State private var navigateToEmail = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppLayout.spacingXLarge) {
                Spacer()
                
                // App branding section with clean text (no card)
                VStack(spacing: AppLayout.spacingLarge) {
                    AppIconView()
                    
                    VStack(spacing: AppLayout.spacingMedium) {
                        Text("Welcome to Quoted")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.lightBackgroundText)
                            .multilineTextAlignment(.center)
                        
                        Text("Discover daily inspiration through curated quotes")
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.lightBackgroundSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .cleanTextSection()
                }
                
                Spacer()
                
                // Continue button with modern styling
                Button {
                    print("🔵 [StartingView] Continue button tapped")
                    navigateToEmail = true
                } label: {
                    Text("Continue")
                }
                .primaryButton()
                .padding(.horizontal, AppLayout.paddingLarge)
                .padding(.bottom, 50)
            }
            .modernBackground()
            .navigationDestination(isPresented: $navigateToEmail) {
                EmailView()
            }
            .onAppear {
                print("🔵 [StartingView] View appeared - Onboarding started")
            }
            .onChange(of: navigateToEmail) { _, newValue in
                if newValue {
                    print("🔵 [StartingView] Navigating to EmailView")
                }
            }
        }
    }
}

#Preview {
    StartingView()
}