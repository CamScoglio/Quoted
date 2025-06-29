import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String?
    let anonymousId: String? // For anonymous users
    let displayName: String?
    let avatarUrl: String?
    let subscriptionTier: SubscriptionTier
    let preferences: UserPreferences
    let createdAt: Date
    let updatedAt: Date
    
    enum SubscriptionTier: String, Codable, CaseIterable {
        case free = "free"
        case premium = "premium"
        case pro = "pro"
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .premium: return "Premium"
            case .pro: return "Pro"
            }
        }
    }
}

// MARK: - User Extensions
extension User {
    var isAnonymous: Bool {
        return email == nil && anonymousId != nil
    }
    
    var isPremium: Bool {
        return subscriptionTier == .premium || subscriptionTier == .pro
    }
    
    var displayNameOrEmail: String {
        return displayName ?? email ?? "Anonymous User"
    }
} 