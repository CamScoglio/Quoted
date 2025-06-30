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
            VStack(spacing: 20) {
                Text("Enter your email")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .onChange(of: email) { _, newValue in
                        print("🟡 [EmailView] Email input changed: '\(newValue)'")
                    }
                
                Button("Continue") {
                    print("🟡 [EmailView] Continue button tapped with email: '\(email)'")
                    saveEmailAndContinue()
                }
                .disabled(email.isEmpty || isLoading)
                .buttonStyle(.borderedProminent)
                
                if isLoading {
                    ProgressView()
                }
            }
            .padding()
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