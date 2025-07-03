//
//  EmailView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import SwiftUI
import Supabase

struct EmailView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var navigateToPhone = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppLayout.spacingXLarge) {
                Spacer()
                
                // Title section with clean text (no card)
                VStack(spacing: AppLayout.spacingMedium) {
                    Text("Enter your email")
                        .font(AppFonts.largeTitle)
                        .foregroundColor(AppColors.lightBackgroundText)
                        .multilineTextAlignment(.center)
                    
                    Text("We'll use this to keep your account secure")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.lightBackgroundSecondaryText)
                        .multilineTextAlignment(.center)
                }
                .cleanTextSection()
                
                // Email input field
                VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                    Text("Email Address")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.lightBackgroundText)
                    
                    TextField("Enter your email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .modernTextField()
                        .onChange(of: email) { _, newValue in
                            print("🟡 [EmailView] Email input changed: '\(newValue)'")
                        }
                }
                .padding(.horizontal, AppLayout.paddingLarge)
                
                Spacer()
                
                // Continue button
                VStack(spacing: AppLayout.spacingMedium) {
                    Button {
                        print("🟡 [EmailView] Continue button tapped with email: '\(email)'")
                        saveEmailAndContinue()
                    } label: {
                        HStack {
                            if isLoading {
                                ModernProgressView()
                            }
                            Text(isLoading ? "Processing..." : "Continue")
                        }
                    }
                    .primaryButton(isEnabled: !email.isEmpty && !isLoading)
                    .disabled(email.isEmpty || isLoading)
                }
                .padding(.horizontal, AppLayout.paddingLarge)
                .padding(.bottom, 50)
            }
            .modernBackground()
            .navigationDestination(isPresented: $navigateToPhone) {
                EnterPhoneView(email: email)
            }
            .onAppear {
                print("🟡 [EmailView] View appeared")
            }
            .onChange(of: navigateToPhone) { _, newValue in
                if newValue {
                    print("🟡 [EmailView] Navigating to EnterPhoneView")
                }
            }
            .onChange(of: isLoading) { _, newValue in
                print("🟡 [EmailView] Loading state changed: \(newValue)")
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveEmailAndContinue() {
        print("🟡 [EmailView] Email collected: '\(email)'")
        print("🟡 [EmailView] Proceeding to phone verification...")
        
        // No need to save email to database yet - we'll create the complete user profile
        // after phone verification succeeds in AuthPhoneView
        navigateToPhone = true
    }
}

#Preview {
    EmailView()
}