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
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var navigateToAuth = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top section with back button and title
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
                                    phoneNumber = formatPhoneNumber(newValue)
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
                
                // Bottom button
                VStack(spacing: 16) {
                    Button(action: sendVerificationCode) {
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
                        .background(phoneNumber.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                    }
                    .disabled(phoneNumber.isEmpty || isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToAuth) {
                AuthPhoneView(phoneNumber: phoneNumber)
            }
            .alert("Verification", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sendVerificationCode() {
        Task {
            isLoading = true
            
            do {
                // Convert formatted phone number to E.164 format
                let cleanNumber = phoneNumber.filter { $0.isNumber }
                let e164Number = "+1\(cleanNumber)"
                
                // Call Twilio Verify API
                let success = await sendTwilioVerification(phoneNumber: e164Number)
                
                if success {
                    // Navigate to verification screen
                    navigateToAuth = true
                } else {
                    alertMessage = "Failed to send verification code. Please try again."
                    showingAlert = true
                }
                
            } catch {
                print("Error sending verification code: \(error)")
                alertMessage = "Failed to send verification code. Please try again."
                showingAlert = true
            }
            
            isLoading = false
        }
    }
    
    private func sendTwilioVerification(phoneNumber: String) async -> Bool {
        // Load Twilio credentials from Config.plist (like SupabaseManager does)
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let accountSID = config["TWILIO_ACCOUNT_SID"] as? String,
              let authToken = config["TWILIO_AUTH_TOKEN"] as? String,
              let serviceSID = config["TWILIO_VERIFY_SERVICE_SID"] as? String else {
            print("❌ Could not load Twilio configuration from Config.plist")
            return false
        }
        
        guard let url = URL(string: "https://verify.twilio.com/v2/Services/\(serviceSID)/Verifications") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create authentication header
        let credentials = "\(accountSID):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let bodyParameters = [
            "To": phoneNumber,
            "Channel": "sms"
        ]
        
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                
                // Check if request was successful (status code 201 for created)
                return httpResponse.statusCode == 201
            }
            
            return false
        } catch {
            print("Network error: \(error)")
            return false
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Remove all non-numeric characters
        let cleaned = number.filter { $0.isNumber }
        
        // Limit to 10 digits
        let limited = String(cleaned.prefix(10))
        
        // Format as (XXX) XXX-XXXX
        switch limited.count {
        case 0...3:
            return limited
        case 4...6:
            let area = String(limited.prefix(3))
            let first = String(limited.dropFirst(3))
            return "(\(area)) \(first)"
        case 7...10:
            let area = String(limited.prefix(3))
            let first = String(limited.dropFirst(3).prefix(3))
            let last = String(limited.dropFirst(6))
            return "(\(area)) \(first)-\(last)"
        default:
            return limited
        }
    }
}

#Preview {
    EnterPhoneView()
}