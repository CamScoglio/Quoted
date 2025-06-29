import Foundation

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    let notificationTime: Date?
    let preferredCategories: [String]
    let favoriteAuthors: [String]
    let themePreference: ThemePreference
    let readingStreak: ReadingStreak
    let privacySettings: PrivacySettings
    
    enum ThemePreference: String, Codable, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    struct ReadingStreak: Codable {
        let currentStreak: Int
        let longestStreak: Int
        let lastReadDate: Date?
        
        init() {
            self.currentStreak = 0
            self.longestStreak = 0
            self.lastReadDate = nil
        }
    }
    
    struct PrivacySettings: Codable {
        let shareReadingStats: Bool
        let allowAnalytics: Bool
        let emailNotifications: Bool
        
        init() {
            self.shareReadingStats = false
            self.allowAnalytics = true
            self.emailNotifications = true
        }
    }
}

// MARK: - Default Preferences
extension UserPreferences {
    static var `default`: UserPreferences {
        return UserPreferences(
            notificationTime: nil,
            preferredCategories: [],
            favoriteAuthors: [],
            themePreference: .system,
            readingStreak: ReadingStreak(),
            privacySettings: PrivacySettings()
        )
    }
} 