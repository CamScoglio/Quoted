//
//  PhoneAuthView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var errorMessage = ""
    @State private var showingOTPInput = false
    @State private var resendTimer = 0
    @State private var canResend = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "phone.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text(showingOTPInput ? "Enter Verification Code" : "Enter Your Phone Number")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(showingOTPInput ? 
                             "We sent a 6-digit code to \(formatPhoneNumber(phoneNumber))" :
                             "We'll send you a verification code via SMS")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Input Section
                    VStack(spacing: 20) {
                        if showingOTPInput {
                            // OTP Input
                            OTPInputView(otpCode: $otpCode)
                                .padding(.horizontal, 40)
                        } else {
                            // Phone Number Input
                            PhoneNumberInputView(phoneNumber: $phoneNumber)
                                .padding(.horizontal, 40)
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        if showingOTPInput {
                            // Verify OTP Button
                            Button(action: verifyOTP) {
                                HStack {
                                    if userManager.isLoading {
                                        ProgressView()
                                            .tint(.primary)
                                    } else {
                                        Text("Verify Code")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(otpCode.count != 6 || userManager.isLoading)
                            .opacity(otpCode.count != 6 || userManager.isLoading ? 0.6 : 1.0)
                            
                            // Resend Button
                            Button(action: resendOTP) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text(canResend ? "Resend Code" : "Resend in \(resendTimer)s")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(canResend ? 0.2 : 0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canResend || userManager.isLoading)
                            .opacity(!canResend || userManager.isLoading ? 0.6 : 1.0)
                            
                        } else {
                            // Send OTP Button
                            Button(action: sendOTP) {
                                HStack {
                                    if userManager.isLoading {
                                        ProgressView()
                                            .tint(.primary)
                                    } else {
                                        Text("Send Code")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(!isValidPhoneNumber || userManager.isLoading)
                            .opacity(!isValidPhoneNumber || userManager.isLoading ? 0.6 : 1.0)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Privacy Notice
                    Text("By continuing, you agree to receive SMS messages. Message and data rates may apply.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if showingOTPInput {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Back") {
                            showingOTPInput = false
                            otpCode = ""
                            errorMessage = ""
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if resendTimer > 0 {
                resendTimer -= 1
            } else {
                canResend = true
            }
        }
        .onChange(of: userManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidPhoneNumber: Bool {
        // Basic phone number validation (you can make this more sophisticated)
        let cleanedNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return cleanedNumber.count >= 10 && cleanedNumber.count <= 15
    }
    
    // MARK: - Actions
    
    private func sendOTP() {
        errorMessage = ""
        
        let cleanedNumber = formatPhoneNumberForAPI(phoneNumber)
        
        Task {
            do {
                try await userManager.sendPhoneOTP(phoneNumber: cleanedNumber)
                await MainActor.run {
                    showingOTPInput = true
                    resendTimer = 60 // 60 second cooldown
                    canResend = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func verifyOTP() {
        errorMessage = ""
        
        let cleanedNumber = formatPhoneNumberForAPI(phoneNumber)
        
        Task {
            do {
                _ = try await userManager.verifyPhoneOTP(phoneNumber: cleanedNumber, otpCode: otpCode)
                // UserManager will handle the authentication state change
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    // Clear OTP on error so user can try again
                    otpCode = ""
                }
            }
        }
    }
    
    private func resendOTP() {
        Task {
            do {
                try await userManager.resendPhoneOTP()
                await MainActor.run {
                    resendTimer = 60
                    canResend = false
                    errorMessage = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Format for display (e.g., +1 (555) 123-4567)
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if cleaned.hasPrefix("+1") && cleaned.count == 12 {
            let index1 = cleaned.index(cleaned.startIndex, offsetBy: 2)
            let index2 = cleaned.index(cleaned.startIndex, offsetBy: 5)
            let index3 = cleaned.index(cleaned.startIndex, offsetBy: 8)
            
            return "+1 (\(cleaned[index1..<index2])) \(cleaned[index2..<index3])-\(cleaned[index3...])"
        }
        return cleaned
    }
    
    private func formatPhoneNumberForAPI(_ number: String) -> String {
        // Clean and format for API (e.g., +15551234567)
        var cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Add country code if not present (assuming US)
        if !cleaned.hasPrefix("+") {
            if cleaned.count == 10 {
                cleaned = "+1" + cleaned
            } else if cleaned.count == 11 && cleaned.hasPrefix("1") {
                cleaned = "+" + cleaned
            }
        }
        
        return cleaned
    }
}

// MARK: - Supporting Views

struct PhoneNumberInputView: View {
    @Binding var phoneNumber: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Text("+1")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.leading, 16)
                
                TextField("(555) 123-4567", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.trailing, 16)
            }
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct OTPInputView: View {
    @Binding var otpCode: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Code")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitView(
                        digit: index < otpCode.count ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)]) : "",
                        isActive: index == otpCode.count
                    )
                }
            }
            .background(
                TextField("", text: $otpCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .opacity(0)
                    .focused($isTextFieldFocused)
                    .onChange(of: otpCode) { newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            otpCode = String(newValue.prefix(6))
                        }
                        // Only allow numbers
                        otpCode = newValue.filter { $0.isNumber }
                    }
            )
            .onTapGesture {
                isTextFieldFocused = true
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct OTPDigitView: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        Text(digit)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 45, height: 55)
            .background(Color.white.opacity(digit.isEmpty ? 0.2 : 0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.white : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
            )
    }
}

#Preview {
    PhoneAuthView()
        .environmentObject(UserManager.shared)
} 