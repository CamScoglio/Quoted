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
    @State private var verificationCode = ""
    @State private var isLoading = false
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
                                verificationCode = String(filtered.prefix(6))
                            }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    Button(action: verifyCode) {
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
                    
                    Button("Didn't receive code? Try again") {
                        // Navigate back to resend
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOffboarding) {
                OffboardingView()
            }
            .alert("Verification", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func verifyCode() {
        Task {
            isLoading = true
            
            // Convert formatted phone number to E.164 format
            let cleanNumber = phoneNumber.filter { $0.isNumber }
            let e164Number = "+1\(cleanNumber)"
            
            // Use TwilioManager to verify code
            let success = await TwilioManager.shared.verifyCode(verificationCode, for: e164Number)
            
            if success {
                print("✅ Code verified successfully!")
                navigateToOffboarding = true
            } else {
                alertMessage = "Invalid verification code. Please try again."
                showingAlert = true
                verificationCode = "" // Clear the code for retry
            }
            
            isLoading = false
        }
    }
}

#Preview {
    AuthPhoneView(phoneNumber: "(555) 123-4567")
}