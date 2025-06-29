import Foundation
import Supabase

// MARK: - User Manager
@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var phoneVerificationInProgress = false
    @Published var phoneNumber: String = ""
    
    private let supabase = SupabaseManager.shared.client
    
    private init() {
        // Initialize with current session if available
        checkCurrentSession()
    }
    
    // MARK: - Phone Authentication Methods
    
    /// Step 1: Send OTP to phone number
    func sendPhoneOTP(phoneNumber: String) async throws {
        isLoading = true
        phoneVerificationInProgress = false
        
        defer { isLoading = false }
        
        do {
            // Send OTP via SMS
            try await supabase.auth.signInWithOTP(phone: phoneNumber)
            
            // Store phone number for verification step
            self.phoneNumber = phoneNumber
            phoneVerificationInProgress = true
            
            print("📱 UserManager: OTP sent to \(phoneNumber)")
        } catch {
            print("❌ UserManager: Failed to send OTP - \(error)")
            throw UserManagerError.otpSendFailed
        }
    }
    
    /// Step 2: Verify OTP and complete authentication
    func verifyPhoneOTP(phoneNumber: String, otpCode: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Verify the 6-digit OTP
            try await supabase.auth.verifyOTP(
                phone: phoneNumber,
                token: otpCode,
                type: .sms
            )
            
            // Get or create user profile
            let user = try await getOrCreateUserProfile(phoneNumber: phoneNumber)
            
            currentUser = user
            isAuthenticated = true
            phoneVerificationInProgress = false
            
            print("✅ UserManager: Phone authentication successful")
            return user
            
        } catch {
            print("❌ UserManager: OTP verification failed - \(error)")
            throw UserManagerError.otpVerificationFailed
        }
    }
    
    /// Continue as anonymous user (skip phone verification)
    func signInAnonymously() async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Create anonymous user with device ID
        let deviceId = await getOrCreateDeviceId()
        
        let anonymousUser = User(
            id: UUID(),
            email: nil,
            anonymousId: deviceId,
            displayName: nil,
            avatarUrl: nil,
            subscriptionTier: .free,
            preferences: .default,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await createUserProfile(user: anonymousUser)
        
        currentUser = anonymousUser
        isAuthenticated = true
        
        print("👤 UserManager: Anonymous authentication successful")
        return anonymousUser
    }
    
    /// Resend OTP if user didn't receive it
    func resendPhoneOTP() async throws {
        guard !phoneNumber.isEmpty else {
            throw UserManagerError.invalidPhoneNumber
        }
        
        try await sendPhoneOTP(phoneNumber: phoneNumber)
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Sign out from Supabase Auth if not anonymous
        if currentUser?.isAnonymous == false {
            try await supabase.auth.signOut()
        }
        
        currentUser = nil
        isAuthenticated = false
        phoneVerificationInProgress = false
        phoneNumber = ""
    }
    
    // MARK: - Profile Management
    
    func updateProfile(displayName: String?, avatarUrl: String?) async throws {
        guard let currentUser = currentUser else {
            throw UserManagerError.notAuthenticated
        }
        
        let updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            anonymousId: currentUser.anonymousId,
            displayName: displayName ?? currentUser.displayName,
            avatarUrl: avatarUrl ?? currentUser.avatarUrl,
            subscriptionTier: currentUser.subscriptionTier,
            preferences: currentUser.preferences,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )
        
        try await updateUserProfile(user: updatedUser)
        self.currentUser = updatedUser
    }
    
    func updatePreferences(_ preferences: UserPreferences) async throws {
        guard let currentUser = currentUser else {
            throw UserManagerError.notAuthenticated
        }
        
        let updatedUser = User(
            id: currentUser.id,
            email: currentUser.email,
            anonymousId: currentUser.anonymousId,
            displayName: currentUser.displayName,
            avatarUrl: currentUser.avatarUrl,
            subscriptionTier: currentUser.subscriptionTier,
            preferences: preferences,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )
        
        try await updateUserProfile(user: updatedUser)
        self.currentUser = updatedUser
    }
    
    // MARK: - Private Helper Methods
    
    private func checkCurrentSession() {
        Task {
            do {
                let session = try await supabase.auth.session
                if session.user != nil {
                    let user = try await fetchCurrentUserProfile()
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                }
            } catch {
                // No current session or error fetching profile
                await MainActor.run {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private func getOrCreateUserProfile(phoneNumber: String) async throws -> User {
        // First try to fetch existing user
        if let existingUser = try? await fetchCurrentUserProfile() {
            return existingUser
        }
        
        // Create new user profile
        let session = try await supabase.auth.session
        guard let userId = session.user?.id else {
            throw UserManagerError.authenticationFailed
        }
        
        let newUser = User(
            id: userId,
            email: nil, // Phone auth doesn't use email
            anonymousId: nil,
            displayName: nil,
            avatarUrl: nil,
            subscriptionTier: .free,
            preferences: .default,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await createUserProfile(user: newUser)
        return newUser
    }
    
    private func createUserProfile(user: User) async throws {
        try await supabase
            .from("users")
            .insert(user)
            .execute()
    }
    
    private func updateUserProfile(user: User) async throws {
        try await supabase
            .from("users")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }
    
    private func fetchCurrentUserProfile() async throws -> User {
        let session = try await supabase.auth.session
        guard let userId = session.user?.id else {
            throw UserManagerError.notAuthenticated
        }
        
        let response: [User] = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let user = response.first else {
            throw UserManagerError.profileNotFound
        }
        
        return user
    }
    
    private func getOrCreateDeviceId() async -> String {
        let deviceIdKey = "QuotedDeviceId"
        
        if let existingDeviceId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existingDeviceId
        }
        
        let newDeviceId = UUID().uuidString
        UserDefaults.standard.set(newDeviceId, forKey: deviceIdKey)
        return newDeviceId
    }
}

// MARK: - User Manager Errors
enum UserManagerError: LocalizedError {
    case authenticationFailed
    case notAuthenticated
    case profileNotFound
    case networkError
    case otpSendFailed
    case otpVerificationFailed
    case invalidPhoneNumber
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .notAuthenticated:
            return "User is not authenticated."
        case .profileNotFound:
            return "User profile not found."
        case .networkError:
            return "Network error occurred. Please try again."
        case .otpSendFailed:
            return "Failed to send verification code. Please check your phone number and try again."
        case .otpVerificationFailed:
            return "Invalid verification code. Please check the code and try again."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        }
    }
} 