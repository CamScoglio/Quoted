import Foundation

// MARK: - Simple User Preferences
struct UserPreferences: Codable {
    let notificationTime: Date?
    let themePreference: ThemePreference
    
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
}

// MARK: - Default Preferences
extension UserPreferences {
    static var `default`: UserPreferences {
        return UserPreferences(
            notificationTime: nil,
            themePreference: .system
        )
    }
} 