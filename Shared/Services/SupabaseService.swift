//
//  SupabaseService.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation
import Supabase

// MARK: - User Profile Model
struct UserProfile: Codable {
    let id: String
    let email: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case updatedAt = "updated_at"
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let urlString = config["SUPABASE_URL"] as? String,
              let key = config["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Could not load Supabase configuration")
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
    
    // MARK: - Phone Authentication Methods
    
    /// Send OTP to phone number using Supabase's built-in phone auth (with Twilio)
    /// - Parameter phoneNumber: E.164 formatted phone number (e.g., "+19842021329")
    /// - Returns: True if SMS sent successfully, false otherwise
    func sendPhoneOTP(_ phoneNumber: String) async -> Bool {
        print("🟢 [SupabaseManager] Sending OTP to phone: \(phoneNumber)")
        
        do {
            try await client.auth.signInWithOTP(phone: phoneNumber)
            print("🟢 ✅ [SupabaseManager] OTP sent successfully via Supabase")
            return true
        } catch {
            print("🟢 ❌ [SupabaseManager] Failed to send OTP: \(error)")
            print("🟢 ❌ [SupabaseManager] Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Verify OTP code and authenticate user with Supabase
    /// - Parameters:
    ///   - phoneNumber: E.164 formatted phone number (e.g., "+19842021329")
    ///   - code: 6-digit OTP code from SMS
    ///   - email: User's email address to store in profile
    /// - Returns: True if authentication successful, false otherwise
    func verifyPhoneOTP(_ phoneNumber: String, code: String, email: String) async -> Bool {
        print("🟢 [SupabaseManager] Verifying OTP for phone: \(phoneNumber)")
        print("🟢 [SupabaseManager] Code: \(code)")
        print("🟢 [SupabaseManager] Email for profile: \(email)")
        
        do {
            let response = try await client.auth.verifyOTP(
                phone: phoneNumber,
                token: code,
                type: .sms
            )
            
            print("🟢 ✅ [SupabaseManager] Phone verification successful!")
            print("🟢 [SupabaseManager] User ID: \(response.user.id)")
            print("🟢 [SupabaseManager] Session created: \(response.session != nil)")
            
            // Update user profile with email data
            let profileSuccess = await updateUserProfile(
                userId: response.user.id,
                email: email
            )
            
            if profileSuccess {
                print("🟢 ✅ [SupabaseManager] User profile updated successfully")
                return true
            } else {
                print("🟢 ❌ [SupabaseManager] Failed to update user profile")
                return false
            }
            
        } catch {
            print("🟢 ❌ [SupabaseManager] Phone verification failed: \(error)")
            print("🟢 ❌ [SupabaseManager] Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates user profile in the users table with email data
    /// - Parameters:
    ///   - userId: Supabase user ID
    ///   - email: User's actual email address
    /// - Returns: True if update successful, false otherwise
    private func updateUserProfile(userId: UUID, email: String) async -> Bool {
        print("🟢 [SupabaseManager] Updating user profile...")
        print("🟢 [SupabaseManager] User ID: \(userId)")
        print("🟢 [SupabaseManager] Email: \(email)")
        print("🟢 [SupabaseManager] Phone number is stored in auth.users automatically")
        
        do {
            let userProfile = UserProfile(
                id: userId.uuidString,
                email: email,
                updatedAt: Date().ISO8601Format()
            )
            
            try await client
                .from("users")
                .upsert(userProfile)
                .execute()
            
            print("🟢 ✅ [SupabaseManager] User profile updated successfully")
            return true
            
        } catch {
            print("🟢 ❌ [SupabaseManager] Failed to update user profile: \(error)")
            print("🟢 ❌ [SupabaseManager] Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Session Management
    
    /// Get current authenticated user
    /// - Returns: Current user session or nil if not authenticated
    func getCurrentUser() async -> User? {
        do {
            let session = try await client.auth.session
            print("🟢 [SupabaseManager] Current user: \(session.user.id)")
            return session.user
        } catch {
            print("🟢 [SupabaseManager] No current user: \(error)")
            return nil
        }
    }
    
    /// Sign out current user
    func signOut() async -> Bool {
        do {
            try await client.auth.signOut()
            print("🟢 ✅ [SupabaseManager] User signed out successfully")
            return true
        } catch {
            print("🟢 ❌ [SupabaseManager] Failed to sign out: \(error)")
            return false
        }
    }
    
    /// Check if user is currently authenticated
    var isAuthenticated: Bool {
        return client.auth.currentUser != nil
    }
} 