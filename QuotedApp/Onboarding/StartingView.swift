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
            VStack(spacing: 40) {
                Spacer()
                
                // App branding section
                VStack(spacing: 20) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Quoted")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Discover daily inspiration through curated quotes")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button at bottom
                Button("Continue") {
                    print("🔵 [StartingView] Continue button tapped")
                    navigateToEmail = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
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