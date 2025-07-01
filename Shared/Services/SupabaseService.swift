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
    
    // MARK: - User Daily Quote Management (ONLY 2 FUNCTIONS)
    
    /// Get current user ID string
    func getCurrentUserId() async -> String? {
        guard let user = await getCurrentUser() else { return nil }
        return user.id.uuidString
    }
    
    /// Assign a random quote to the current user for today
    func assignRandomQuoteToUser() async throws -> DailyQuote {
        print("🟡 [SupabaseService] assignRandomQuoteToUser() called")
        
        guard let currentUser = await getCurrentUser() else {
            print("🔴 [SupabaseService] No authenticated user found")
            throw QuoteError.userNotAuthenticated
        }
        
        // Debug: Check different ways to get user ID
        let userIdFromUser = currentUser.id.uuidString
        let userIdFromSession = try? await client.auth.session.user.id.uuidString
        print("🔍 [SupabaseService] User ID from currentUser: \(userIdFromUser)")
        print("🔍 [SupabaseService] User ID from session: \(userIdFromSession ?? "nil")")
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        print("🟡 [SupabaseService] Assigning quote for user \(currentUser.id) on \(today)")
        
        // Get random quote with full data
        let countResponse = try await client.from("quotes").select("id", head: true, count: .exact).execute()
        guard let totalCount = countResponse.count, totalCount > 0 else {
            print("🔴 [SupabaseService] No quotes available in database")
            throw QuoteError.noQuotesAvailable
        }
        
        let randomOffset = Int.random(in: 0..<totalCount)
        print("🟡 [SupabaseService] Selecting random quote at offset \(randomOffset) of \(totalCount)")
        
        let quoteResponse: [DailyQuote] = try await client
            .from("quotes")
            .select("*, authors!inner(*), categories!inner(*)")
            .range(from: randomOffset, to: randomOffset)
            .execute().value
        
        guard let randomQuote = quoteResponse.first else {
            print("🔴 [SupabaseService] Failed to get random quote")
            throw QuoteError.noQuotesAvailable
        }
        
        print("🟡 [SupabaseService] Selected quote: '\(randomQuote.quoteText)' by \(randomQuote.authors.name)")
        
        // Use upsert to either update existing row or insert new one
        print("🟡 [SupabaseService] Upserting user's daily quote for today...")
        let upsertData = [
            "user_id": currentUser.id.uuidString.lowercased(),
            "quote_id": randomQuote.id.uuidString.lowercased(),
            "assigned_date": today,
            "is_viewed": "true",
            "viewed_at": Date().ISO8601Format()
        ]
        
        print("🔍 [SupabaseService] Upsert data: \(upsertData)")
        
        let upsertResult = try await client
            .from("user_daily_quotes")
            .upsert(upsertData, onConflict: "user_id,assigned_date")
            .execute()
        
        print("🔍 [SupabaseService] Upsert completed: \(upsertResult.count ?? 0) rows affected")
        print("🟡 [SupabaseService] ✅ Database upsert completed successfully")
        print("🟢 [SupabaseService] ✅ Successfully assigned new quote to user!")
        return randomQuote
    }
    
    /// Get the current user's daily quote
    func getUserDailyQuote() async throws -> DailyQuote? {
        guard let currentUser = await getCurrentUser() else {
            throw QuoteError.userNotAuthenticated
        }
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        
        do {
            // Query quotes table and join user_daily_quotes to get the user's specific quote for today
            let response: [DailyQuote] = try await client
                .from("quotes")
                .select("*, authors!inner(*), categories!inner(*), user_daily_quotes!inner(user_id, assigned_date)")
                .eq("user_daily_quotes.user_id", value: currentUser.id.uuidString.lowercased())
                .eq("user_daily_quotes.assigned_date", value: today)
                .execute().value
            
            return response.first
        } catch {
            print("📝 Error in getUserDailyQuote: \(error)")
            throw QuoteError.databaseError(error.localizedDescription)
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Simple Errors
enum QuoteError: LocalizedError {
    case userNotAuthenticated
    case noQuotesAvailable
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated: return "User must be authenticated"
        case .noQuotesAvailable: return "No quotes available"
        case .databaseError(let message): return message
        }
    }
} 