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

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    // App Group for sharing data between app and widget
    private let appGroup = "group.com.Scoglio.Quoted"
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }
    
    init() {
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
        print("🟢 [SupabaseService] Sending OTP to phone: \(phoneNumber)")
        
        do {
            try await client.auth.signInWithOTP(phone: phoneNumber)
            print("🟢 ✅ [SupabaseService] OTP sent successfully via Supabase")
            return true
        } catch {
            print("�� ❌ [SupabaseService] Failed to send OTP: \(error)")
            print("🟢 ❌ [SupabaseService] Error details: \(error.localizedDescription)")
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
        print("🟢 [SupabaseService] Verifying OTP for phone: \(phoneNumber)")
        print("🟢 [SupabaseService] Code: \(code)")
        print("🟢 [SupabaseService] Email for profile: \(email)")
        
        do {
            let response = try await client.auth.verifyOTP(
                phone: phoneNumber,
                token: code,
                type: .sms
            )
            
            print("🟢 ✅ [SupabaseService] Phone verification successful!")
            print("🟢 [SupabaseService] User ID: \(response.user.id)")
            print("🟢 [SupabaseService] Session created: \(response.session != nil)")
            
            // Save authentication state for widget access
            saveSharedAuthState(userId: response.user.id.uuidString)
            
            // Update user profile with email data
            let profileSuccess = await updateUserProfile(
                userId: response.user.id,
                email: email
            )
            
            if profileSuccess {
                print("🟢 ✅ [SupabaseService] User profile updated successfully")
                return true
            } else {
                print("🟢 ❌ [SupabaseService] Failed to update user profile")
                return false
            }
            
        } catch {
            print("🟢 ❌ [SupabaseService] Phone verification failed: \(error)")
            print("🟢 ❌ [SupabaseService] Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Updates user profile in the users table with email data
    /// - Parameters:
    ///   - userId: Supabase user ID
    ///   - email: User's actual email address
    /// - Returns: True if update successful, false otherwise
    private func updateUserProfile(userId: UUID, email: String) async -> Bool {
        print("🟢 [SupabaseService] Updating user profile...")
        print("🟢 [SupabaseService] User ID: \(userId)")
        print("🟢 [SupabaseService] Email: \(email)")
        print("🟢 [SupabaseService] Phone number is stored in auth.users automatically")
        
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
            
            print("🟢 ✅ [SupabaseService] User profile updated successfully")
            return true
            
        } catch {
            print("🟢 ❌ [SupabaseService] Failed to update user profile: \(error)")
            print("🟢 ❌ [SupabaseService] Error details: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Session Management
    
    /// Get current authenticated user
    /// - Returns: Current user session or nil if not authenticated
    func getCurrentUser() async -> User? {
        do {
            let session = try await client.auth.session
            print("🟢 [SupabaseService] Current user: \(session.user.id)")
            return session.user
        } catch {
            print("🟢 [SupabaseService] No current user: \(error)")
            return nil
        }
    }
    
    /// Sign out current user
    func signOut() async -> Bool {
        do {
            try await client.auth.signOut()
            clearSharedAuthState()
            print("🟢 ✅ [SupabaseService] User signed out successfully")
            return true
        } catch {
            print("🟢 ❌ [SupabaseService] Failed to sign out: \(error)")
            return false
        }
    }
    
    // MARK: - Shared Authentication State (for Widget)
    
    /// Save authentication state to shared UserDefaults for widget access
    private func saveSharedAuthState(userId: String) {
        sharedUserDefaults?.set(true, forKey: "isAuthenticated")
        sharedUserDefaults?.set(userId, forKey: "currentUserId")
        print("🟢 [SupabaseService] Saved shared auth state for user: \(userId)")
    }
    
    /// Clear authentication state from shared UserDefaults
    private func clearSharedAuthState() {
        sharedUserDefaults?.removeObject(forKey: "isAuthenticated")
        sharedUserDefaults?.removeObject(forKey: "currentUserId")
        print("🟢 [SupabaseService] Cleared shared auth state")
    }
    
    /// Get current user ID from shared state (for widget use)
    func getSharedUserId() -> String? {
        return sharedUserDefaults?.string(forKey: "currentUserId")
    }
    
    // MARK: - User Daily Quote Management
    
    /// Get current user ID string
    func getCurrentUserId() async -> String? {
        guard let user = await getCurrentUser() else { return nil }
        return user.id.uuidString
    }
    
    /// Assign a random quote to the current user for today
    func assignRandomQuoteToUser() async throws -> DailyQuote {
        print("🟡 [SupabaseService] assignRandomQuoteToUser() called")
        
        // Try session first, fall back to shared user ID for widget
        var userId: String
        if let currentUser = await getCurrentUser() {
            userId = currentUser.id.uuidString
            print("🟡 [SupabaseService] Using session user ID: \(userId)")
        } else if let sharedUserId = getSharedUserId() {
            userId = sharedUserId
            print("🟡 [SupabaseService] Using shared user ID for widget: \(userId)")
        } else {
            print("🔴 [SupabaseService] No authenticated user found")
            throw QuoteError.userNotAuthenticated
        }
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        print("🟡 [SupabaseService] Assigning quote for user \(userId) on \(today)")
        
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
            "user_id": userId.lowercased(),
            "quote_id": randomQuote.id.uuidString.lowercased(),
            "assigned_date": today,
            "is_viewed": "true",
            "viewed_at": Date().ISO8601Format()
        ]
        
        print("🔍 [SupabaseService] Upsert data: \(upsertData)")
        
        do {
            let upsertResult = try await client
                .from("user_daily_quotes")
                .upsert(upsertData, onConflict: "user_id,assigned_date")
                .execute()
            
            print("🔍 [SupabaseService] Upsert completed: \(upsertResult.count ?? 0) rows affected")
            print("🟡 [SupabaseService] ✅ Database upsert completed successfully")
            print("🟢 [SupabaseService] ✅ Successfully assigned new quote to user!")
            
            // Save to shared storage for cross-app sync
            saveQuoteToSharedStorage(randomQuote)
            
            // Trigger sync if this was called from widget
            if await getCurrentUser() == nil {
                triggerSync()
                print("🔄 [Widget] Triggered app sync")
            }
            
            return randomQuote
        } catch {
            print("🔴 [SupabaseService] Upsert failed: \(error)")
            throw QuoteError.databaseError(error.localizedDescription)
        }
    }
    
    /// Get the current user's daily quote
    func getUserDailyQuote() async throws -> DailyQuote? {
        // Try session first, fall back to shared user ID for widget
        var userId: String
        if let currentUser = await getCurrentUser() {
            userId = currentUser.id.uuidString
            print("🟡 [SupabaseService] Using session user ID: \(userId)")
        } else if let sharedUserId = getSharedUserId() {
            userId = sharedUserId
            print("🟡 [SupabaseService] Using shared user ID for widget: \(userId)")
        } else {
            throw QuoteError.userNotAuthenticated
        }
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        
        do {
            // Query quotes table and join user_daily_quotes to get the user's specific quote for today
            let response: [DailyQuote] = try await client
                .from("quotes")
                .select("*, authors!inner(*), categories!inner(*), user_daily_quotes!inner(user_id, assigned_date)")
                .eq("user_daily_quotes.user_id", value: userId.lowercased())
                .eq("user_daily_quotes.assigned_date", value: today)
                .execute().value
            
            let quote = response.first
            
            // Save to shared storage for cross-app sync
            if let quote = quote {
                saveQuoteToSharedStorage(quote)
            }
            
            return quote
        } catch {
            print("📝 Error in getUserDailyQuote: \(error)")
            throw QuoteError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Shared Storage & Sync
    
    /// Save quote to shared UserDefaults for cross-app sync
    func saveQuoteToSharedStorage(_ quote: DailyQuote) {
        guard let data = try? JSONEncoder().encode(quote) else { return }
        sharedUserDefaults?.set(data, forKey: "currentDailyQuote")
        sharedUserDefaults?.set(Date().timeIntervalSince1970, forKey: "quoteLastUpdated")
        
        // CRITICAL: Force synchronization to disk before widget reload
        // This prevents the race condition where widget timeline is generated
        // before UserDefaults data is flushed to disk
        sharedUserDefaults?.synchronize()
        
        print("🔄 [Sync] Quote saved to shared storage: '\(quote.quoteText)' by \(quote.authors.name)")
        print("🔍 [Sync] Quote ID: \(quote.id)")
        print("💾 [Sync] UserDefaults synchronized to disk")
    }
    
    /// Get quote from shared UserDefaults
    func getQuoteFromSharedStorage() -> DailyQuote? {
        guard let data = sharedUserDefaults?.data(forKey: "currentDailyQuote"),
              let quote = try? JSONDecoder().decode(DailyQuote.self, from: data) else {
            return nil
        }
        return quote
    }
    
    /// Check if app needs to sync (for polling)
    func needsSync() -> Bool {
        let needs = sharedUserDefaults?.bool(forKey: "needsSync") ?? false
        if needs {
            // Clear the flag
            sharedUserDefaults?.set(false, forKey: "needsSync")
        }
        return needs
    }
    
    /// Mark that sync is needed
    func triggerSync() {
        sharedUserDefaults?.set(true, forKey: "needsSync")
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
