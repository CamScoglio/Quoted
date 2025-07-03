//
//  AppStyles.swift
//  Quoted
//
//  Modern design system for Quoted app
//

import SwiftUI

// MARK: - Colors & Gradients
struct AppColors {
    // Primary brand colors
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 1.0)
    static let primaryPurple = Color(red: 0.6, green: 0.3, blue: 1.0)
    
    // Background gradients
    static let mainGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.98, green: 0.95, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.9),
            Color.white.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [primaryBlue, primaryPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Text colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let accentText = primaryBlue
    
    // Text colors for light backgrounds (onboarding, etc.)
    static let lightBackgroundText = Color.black
    static let lightBackgroundSecondaryText = Color.gray
    
    // Adaptive colors for colored backgrounds
    static let overlayText = Color.white
    static let overlayTextSecondary = Color.white.opacity(0.9)
    static let overlayTextTertiary = Color.white.opacity(0.7)
    
    // Platform-adaptive text colors
    static let adaptiveOverlayText: Color = {
        #if targetEnvironment(macCatalyst)
        return Color.primary
        #else
        return Color.white
        #endif
    }()
    
    static let adaptiveOverlayTextSecondary: Color = {
        #if targetEnvironment(macCatalyst)
        return Color.secondary
        #else
        return Color.white.opacity(0.9)
        #endif
    }()
}

// MARK: - Typography
struct AppFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let headline = Font.headline.weight(.medium)
    static let body = Font.body
    static let subheadline = Font.subheadline
    static let caption = Font.caption
}

// MARK: - Spacing & Layout
struct AppLayout {
    static let cornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 20
    
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 32
    static let paddingXLarge: CGFloat = 40
    
    static let spacingSmall: CGFloat = 12
    static let spacingMedium: CGFloat = 20
    static let spacingLarge: CGFloat = 32
    static let spacingXLarge: CGFloat = 40
}

// MARK: - Custom View Modifiers
struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .fill(AppColors.cardGradient)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

struct ModernTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(AppColors.lightBackgroundText) // Explicit input text color
            .accentColor(AppColors.accentText) // Cursor color
            .tint(AppColors.accentText) // iOS 15+ cursor and selection color
            .padding(AppLayout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .fill(Color.white.opacity(0.8))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                // This helps ensure placeholder text is also properly colored
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.clear)
            )
    }
}

struct CleanTextSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppLayout.paddingLarge)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(AppLayout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                    .fill(isEnabled ? AppColors.buttonGradient : LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(color: isEnabled ? AppColors.primaryBlue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.accentText)
            .padding(.vertical, AppLayout.paddingSmall)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Components
struct ModernBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.title2)
                .foregroundColor(AppColors.lightBackgroundText)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct ModernProgressView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.adaptiveOverlayText))
            .scaleEffect(0.8)
    }
}

struct SuccessCheckmark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct AppIconView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.buttonGradient)
                .frame(width: 100, height: 100)
                .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 15, x: 0, y: 8)
            
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.adaptiveOverlayText)
        }
    }
}

// MARK: - View Extensions
extension View {
    func modernCard() -> some View {
        modifier(ModernCardStyle())
    }
    
    func modernTextField() -> some View {
        modifier(ModernTextFieldStyle())
    }
    
    func cleanTextSection() -> some View {
        modifier(CleanTextSectionStyle())
    }
    
    func primaryButton(isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func modernBackground() -> some View {
        background(AppColors.mainGradient.ignoresSafeArea())
    }
    
    /// Ensures text field has proper colors on all platforms
    func textFieldColors() -> some View {
        self.foregroundColor(AppColors.lightBackgroundText)
            .accentColor(AppColors.accentText)
            .tint(AppColors.accentText)
    }
} 