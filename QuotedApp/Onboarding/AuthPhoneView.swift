//put in 6-digit code (authetnicated through Supabase and Twilio)
//Re-try if doesn't work
//Send to OffboardingView

import Foundation
import SwiftUI
import Supabase
import WidgetKit

//put in 6-digit code that was sent to the phone number (authenticated through Twilio and EnterPhoneNumber.swift)
//Re-try if code is wrong
//Send to OffboardingView

struct AuthPhoneView: View {
    let phoneNumber: String
    let email: String
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var navigateToOffboarding = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top section with modern back button
                HStack {
                    ModernBackButton {
                        print("🔴 [AuthPhoneView] Back button tapped")
                        dismiss()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AppLayout.paddingMedium)
                .padding(.top, 10)
                
                // Main content area
                VStack(spacing: AppLayout.spacingXLarge) {
                    Spacer()
                    
                    // Title section with clean text (no card)
                    VStack(spacing: AppLayout.spacingMedium) {
                        Text("Enter verification code")
                            .font(AppFonts.largeTitle)
                            .foregroundColor(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: AppLayout.spacingSmall) {
                            Text("We sent a 6-digit code to")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(phoneNumber)
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.accentText)
                        }
                    }
                    .cleanTextSection()
                    
                    // 6-digit code input with modern styling
                    VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                        Text("Verification Code")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.primaryText)
                        
                        TextField("000000", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .modernTextField()
                            .onChange(of: verificationCode) { _, newValue in
                                // Limit to 6 digits
                                let filtered = newValue.filter { $0.isNumber }
                                let limited = String(filtered.prefix(6))
                                print("🔴 [AuthPhoneView] Code input changed: '\(newValue)' -> filtered: '\(limited)'")
                                verificationCode = limited
                            }
                    }
                    .padding(.horizontal, AppLayout.paddingLarge)
                    
                    Spacer()
                    Spacer()
                }
                
                // Bottom buttons with modern styling
                VStack(spacing: AppLayout.spacingMedium) {
                    Button {
                        print("🔴 [AuthPhoneView] Verify Code button tapped")
                        print("🔴 [AuthPhoneView] Current code: '\(verificationCode)' (length: \(verificationCode.count))")
                        verifyCode()
                    } label: {
                        HStack {
                            if isLoading {
                                ModernProgressView()
                            }
                            Text(isLoading ? "Verifying..." : "Verify Code")
                        }
                    }
                    .primaryButton(isEnabled: verificationCode.count == 6 && !isLoading)
                    .disabled(verificationCode.count != 6 || isLoading)
                    
                    Button(isResending ? "Sending..." : "Didn't receive code? Resend") {
                        print("🔴 [AuthPhoneView] Resend code button tapped")
                        resendVerificationCode()
                    }
                    .secondaryButton()
                    .disabled(isResending)
                }
                .padding(.horizontal, AppLayout.paddingLarge)
                .padding(.bottom, 50)
            }
            .modernBackground()
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOffboarding) {
                OffboardingView()
            }
            .onAppear {
                print("🔴 [AuthPhoneView] View appeared for phone: \(phoneNumber)")
            }
            .onChange(of: navigateToOffboarding) { _, newValue in
                if newValue {
                    print("🔴 [AuthPhoneView] Navigating to OffboardingView")
                }
            }
            .onChange(of: isLoading) { _, newValue in
                print("🔴 [AuthPhoneView] Loading state changed: \(newValue)")
            }
            .alert("Verification", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: showingAlert) { _, newValue in
                if newValue {
                    print("🔴 [AuthPhoneView] Alert shown: '\(alertMessage)'")
                }
            }
        }
    }
    
    private func verifyCode() {
        Task {
            print("🔴 [AuthPhoneView] Starting code verification process...")
            isLoading = true
            
            // Convert formatted phone number to E.164 format
            let cleanNumber = phoneNumber.filter { $0.isNumber }
            let e164Number = "+1\(cleanNumber)"
            
            NSLog("🔴 [AuthPhoneView] Formatted phone: '\(phoneNumber)'")
            NSLog("🔴 [AuthPhoneView] Clean number: '\(cleanNumber)' (length: \(cleanNumber.count))")
            NSLog("🔴 [AuthPhoneView] E.164 format: '\(e164Number)'")
            print("🔴 [AuthPhoneView] Verification code: '\(verificationCode)'")
            
            // Use Supabase phone authentication instead of separate Twilio calls
            print("🔴 [AuthPhoneView] Calling SupabaseManager.verifyPhoneOTP...")
            let success = await SupabaseService.shared.verifyPhoneOTP(e164Number, code: verificationCode, email: email)
            
            print("🔴 [AuthPhoneView] SupabaseManager.verifyPhoneOTP result: \(success)")
            
            if success {
                print("🔴 ✅ [AuthPhoneView] Phone verification and authentication successful!")
                
                WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
                
                navigateToOffboarding = true
            } else {
                print("🔴 ❌ [AuthPhoneView] Phone verification failed")
                alertMessage = "Invalid verification code. Please try again."
                showingAlert = true
                verificationCode = "" // Clear the code for retry
                print("🔴 [AuthPhoneView] Code cleared for retry")
            }
            
            isLoading = false
            print("🔴 [AuthPhoneView] Code verification process completed")
        }
    }
    
    private func resendVerificationCode() {
        Task {
            print("🔴 [AuthPhoneView] Starting code resend process...")
            isResending = true
            
            // Convert formatted phone number to E.164 format
            let cleanNumber = phoneNumber.filter { $0.isNumber }
            let e164Number = "+1\(cleanNumber)"
            
            NSLog("🔴 [AuthPhoneView] Resending to phone: '\(phoneNumber)'")
            NSLog("🔴 [AuthPhoneView] E.164 format: '\(e164Number)'")
            
            // Use SupabaseManager to resend OTP instead of TwilioManager
            print("🔴 [AuthPhoneView] Calling SupabaseManager.sendPhoneOTP...")
            let success = await SupabaseService.shared.sendPhoneOTP(e164Number)
            
            print("🔴 [AuthPhoneView] SupabaseManager.sendPhoneOTP result: \(success)")
            
            if success {
                print("🔴 ✅ [AuthPhoneView] Verification code resent successfully!")
                alertMessage = "Verification code sent! Please check your messages."
                showingAlert = true
                verificationCode = "" // Clear any existing code
            } else {
                print("🔴 ❌ [AuthPhoneView] Failed to resend verification code")
                alertMessage = "Failed to resend verification code. Please try again."
                showingAlert = true
            }
            
            isResending = false
            print("🔴 [AuthPhoneView] Code resend process completed")
        }
    }
}

#Preview {
    AuthPhoneView(phoneNumber: "(555) 123-4567", email: "test@example.com")
}
