//put in 6-digit code (authetnicated through Supabase and Twilio)
//Re-try if doesn't work
//Send to OffboardingView

import Foundation
import SwiftUI
import Supabase

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
                // Top section with back button
                HStack {
                    Button(action: {
                        print("🔴 [AuthPhoneView] Back button tapped")
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Main content area
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Title section
                    VStack(spacing: 16) {
                        Text("Enter verification code")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("We sent a 6-digit code to")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(phoneNumber)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 32)
                    
                    // 6-digit code input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("000000", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                            .onChange(of: verificationCode) { _, newValue in
                                // Limit to 6 digits
                                let filtered = newValue.filter { $0.isNumber }
                                let limited = String(filtered.prefix(6))
                                print("🔴 [AuthPhoneView] Code input changed: '\(newValue)' -> filtered: '\(limited)'")
                                verificationCode = limited
                            }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    Button(action: {
                        print("🔴 [AuthPhoneView] Verify Code button tapped")
                        print("🔴 [AuthPhoneView] Current code: '\(verificationCode)' (length: \(verificationCode.count))")
                        verifyCode()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Verifying..." : "Verify Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.count == 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                    }
                    .disabled(verificationCode.count != 6 || isLoading)
                    
                    Button(isResending ? "Sending..." : "Didn't receive code? Resend") {
                        print("🔴 [AuthPhoneView] Resend code button tapped")
                        resendVerificationCode()
                    }
                    .font(.subheadline)
                    .foregroundColor(isResending ? .gray : .blue)
                    .disabled(isResending)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
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
                
                // Create user_daily_quotes row immediately after successful authentication
                do {
                    _ = try await SupabaseService.shared.assignRandomQuoteToUser()
                    print("🔴 ✅ [AuthPhoneView] user_daily_quotes row created for new user")
                } catch {
                    print("🔴 ❌ [AuthPhoneView] Failed to create user_daily_quotes row: \(error)")
                    // Continue to offboarding even if quote assignment fails
                }
                
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
