import Foundation

// MARK: - Simple User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String?
    let anonymousId: String? // For anonymous users
    let displayName: String?
    let avatarUrl: String?
    let preferences: UserPreferences
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case anonymousId = "anonymous_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Extensions
extension User {
    var isAnonymous: Bool {
        return email == nil && anonymousId != nil
    }
    
    var displayNameOrEmail: String {
        return displayName ?? email ?? "Anonymous User"
    }
} 