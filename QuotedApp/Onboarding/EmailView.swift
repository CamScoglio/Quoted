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
                
                Button("Continue") {
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
                EnterPhoneView()
            }
        }
    }
    
    private func saveEmailAndContinue() {
        Task {
            isLoading = true
            
            do {
                try await SupabaseManager.shared.client
                    .from("users")
                    .insert([
                        "email": email
                    ])
                    .execute()
                
                // Navigate to phone view after successful save
                navigateToPhone = true
                
            } catch {
                print("Error inserting email: \(error)")
                // Handle error - maybe show an alert
            }
            
            isLoading = false
        }
    }
}

#Preview {
    EmailView()
}