//
//  EnterPhoneView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import SwiftUI
import Supabase

struct EnterPhoneView: View {
    let email: String
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var navigateToAuth = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var agreedToSMS = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top section with back button and title
                HStack {
                    Button(action: {
                        print("🟠 [EnterPhoneView] Back button tapped")
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
                    
                    // Title section - centered toward top
                    VStack(spacing: 16) {
                        Text("Enter your phone number")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("We'll send you a verification code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    // Phone number input field - modern styling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("+1")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            
                            TextField("(555) 123-4567", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: phoneNumber) { _, newValue in
                                    let formatted = formatPhoneNumber(newValue)
                                    print("🟠 [EnterPhoneView] Phone input changed: '\(newValue)' -> formatted: '\(formatted)'")
                                    phoneNumber = formatted
                                }
                        }
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
                
                // Bottom section with agreement and button
                VStack(spacing: 16) {
                    // SMS Agreement Checkbox
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            agreedToSMS.toggle()
                            print("🟠 [EnterPhoneView] SMS agreement toggled: \(agreedToSMS)")
                        }) {
                            Image(systemName: agreedToSMS ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(agreedToSMS ? .blue : .secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text("I authorize Quoted to send a text (SMS/MMS) message containing a verification code to the mobile phone number I have provided. I understand that message and data rates may apply, that this message is transactional and not marketing in nature, and that I may revoke my consent at any time prior to completion of the verification process by closing the application or contacting support")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    
                    // Verification Button
                    Button(action: {
                        print("🟠 [EnterPhoneView] Send Verification Code button tapped")
                        print("🟠 [EnterPhoneView] Current phone number: '\(phoneNumber)'")
                        sendVerificationCode()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Sending..." : "Send Verification Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((phoneNumber.isEmpty || !agreedToSMS) ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                    }
                    .disabled(phoneNumber.isEmpty || !agreedToSMS || isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthPhoneView(phoneNumber: phoneNumber, email: email)
            }
            .onAppear {
                print("🟠 [EnterPhoneView] View appeared")
            }
            .onChange(of: navigateToAuth) { _, newValue in
                if newValue {
                    print("🟠 [EnterPhoneView] Navigating to AuthPhoneView")
                }
            }
            .onChange(of: isLoading) { _, newValue in
                print("🟠 [EnterPhoneView] Loading state changed: \(newValue)")
            }
            .alert("Verification", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: showingAlert) { _, newValue in
                if newValue {
                    print("🟠 [EnterPhoneView] Alert shown: '\(alertMessage)'")
                }
            }
        }
    }
    
    private func sendVerificationCode() {
        Task {
            print("🟠 [EnterPhoneView] Starting verification code send process...")
            isLoading = true
            
            // Convert formatted phone number to E.164 format
            let cleanNumber = phoneNumber.filter { $0.isNumber }
            let e164Number = "+1\(cleanNumber)"
            
            NSLog("🟠 [EnterPhoneView] Formatted phone: '\(phoneNumber)'")
            NSLog("🟠 [EnterPhoneView] Clean number: '\(cleanNumber)' (length: \(cleanNumber.count))")
            NSLog("🟠 [EnterPhoneView] E.164 format: '\(e164Number)'")
            
            // Use Supabase phone authentication instead of direct Twilio API
            print("🟠 [EnterPhoneView] Calling SupabaseManager.sendPhoneOTP...")
            let success = await SupabaseService.shared.sendPhoneOTP(e164Number)
            
            print("🟠 [EnterPhoneView] SupabaseManager.sendPhoneOTP result: \(success)")
            
            if success {
                print("🟠 ✅ [EnterPhoneView] Verification code sent successfully")
                // Navigate to verification screen
                navigateToAuth = true
            } else {
                print("🟠 ❌ [EnterPhoneView] Failed to send verification code")
                alertMessage = "Failed to send verification code. Please try again."
                showingAlert = true
            }
            
            isLoading = false
            print("🟠 [EnterPhoneView] Verification code send process completed")
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove all non-numeric characters
        let cleaned = number.filter { $0.isNumber }
        
        // Handle 11-digit numbers starting with 1 (remove the country code)
        let workingNumber: String
        if cleaned.count == 11 && cleaned.hasPrefix("1") {
            // Remove the leading 1 (country code) to get 10-digit number
            workingNumber = String(cleaned.dropFirst())
            NSLog("🟠 [EnterPhoneView] 11-digit number detected, removing country code: '\(cleaned)' -> '\(workingNumber)'")
        } else {
            // Limit to 10 digits for other cases
            workingNumber = String(cleaned.prefix(10))
        }
        
        // Format as (XXX) XXX-XXXX
        switch workingNumber.count {
        case 0...3:
            return workingNumber
        case 4...6:
            let area = String(workingNumber.prefix(3))
            let first = String(workingNumber.dropFirst(3))
            return "(\(area)) \(first)"
        case 7...10:
            let area = String(workingNumber.prefix(3))
            let first = String(workingNumber.dropFirst(3).prefix(3))
            let last = String(workingNumber.dropFirst(6))
            return "(\(area)) \(first)-\(last)"
        default:
            return workingNumber
        }
    }
}

#Preview {
    EnterPhoneView(email: "test@example.com")
}
