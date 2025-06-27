import SwiftUI

// MARK: - Widget Styles Configuration
struct WidgetStyles {
    
    // MARK: - Colors
    struct Colors {
        // Text Colors
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.8)
        static let tertiaryText = Color.white.opacity(0.7)
        static let quaternaryText = Color.white.opacity(0.6)
        static let buttonText = Color.white.opacity(0.9)
        
        // Background Colors
        static let buttonBackground = Color.white.opacity(0.2)
        static let fallbackGradientStart = Color.blue
        static let fallbackGradientEnd = Color.purple
    }
    
    // MARK: - Typography
    struct Typography {
        // Small Widget
        struct Small {
            static let quoteFont = Font.caption
            static let quoteFontWeight = Font.Weight.medium
            static let authorFont = Font.caption2
            static let authorFontWeight = Font.Weight.semibold
            static let buttonFont = Font.caption2
            static let buttonFontWeight = Font.Weight.semibold
        }
        
        // Medium Widget
        struct Medium {
            static let quoteFont = Font.system(size: 14, weight: .medium, design: .rounded)
            static let authorFont = Font.caption
            static let authorFontWeight = Font.Weight.semibold
            static let professionFont = Font.caption2
            static let buttonFont = Font.caption2
            static let buttonFontWeight = Font.Weight.semibold
        }
        
        // Large Widget
        struct Large {
            static let headerFont = Font.caption2
            static let headerFontWeight = Font.Weight.bold
            static let dateFont = Font.caption2
            static let quoteFont = Font.system(size: 16, weight: .medium, design: .rounded)
            static let authorFont = Font.system(size: 15, weight: .semibold)
            static let professionFont = Font.caption
            static let buttonFont = Font.caption2
            static let buttonFontWeight = Font.Weight.semibold
        }
        
        // Icons
        struct Icons {
            static let smallQuoteIcon = Font.title2
            static let mediumQuoteIcon = Font.title3
            static let largeQuoteIcon = Font.largeTitle
            static let buttonIcon = Font.caption2
        }
    }
    
    // MARK: - Spacing & Layout
    struct Layout {
        // Widget Padding
        static let smallWidgetPadding: CGFloat = 12
        static let mediumWidgetPadding: CGFloat = 16
        static let largeWidgetPadding: CGFloat = 20
        
        // Corner Radius
        static let widgetCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 0
        static let largeButtonCornerRadius: CGFloat = 10
        
        // Spacing
        struct Spacing {
            static let small: CGFloat = 4
            static let medium: CGFloat = 8
            static let large: CGFloat = 12
            static let extraLarge: CGFloat = 16
            static let huge: CGFloat = 20
        }
        
        // Button Padding
        struct Button {
            static let horizontalPadding: CGFloat = 0
            static let verticalPadding: CGFloat = 0
            static let largeHorizontalPadding: CGFloat = 0
            static let largeVerticalPadding: CGFloat = 0
        }
    }
    
    // MARK: - Text Limits
    struct TextLimits {
        static let smallQuoteLineLimit = 3
        static let mediumQuoteLineLimit = 4
        static let largeQuoteLineLimit = 6
        static let authorLineLimit = 1
        static let smallQuoteTruncation = 100
        static let smallQuoteTruncationSuffix = "..."
        static let quoteLineSpacing: CGFloat = 2
    }
    
    // MARK: - Icons
    struct IconNames {
        static let quote = "quote.bubble.fill"
        static let nextArrow = "arrow.right"
    }
    
    // MARK: - Gradient Configuration
    struct Gradient {
        static let startPoint = UnitPoint.topLeading
        static let endPoint = UnitPoint.bottomTrailing
    }
    
    // MARK: - Text Labels
    struct Labels {
        static let dailyQuoteHeader = "DAILY QUOTE"
        static let nextButtonText = "Next"
        static let authorPrefix = "— "
    }
    
    // MARK: - Date Formatting
    struct DateFormat {
        static let datePattern = "MMMM d, yyyy"
    }
}

// MARK: - Style Helper Extensions
extension WidgetStyles {
    
    // Helper method to get gradient colors from quote data
    static func gradientColors(from quote: Quote) -> [Color] {
        guard let gradient = quote.backgroundGradient,
              let startHex = gradient["start"],
              let endHex = gradient["end"] else {
            return [Colors.fallbackGradientStart, Colors.fallbackGradientEnd]
        }
        
        return [Color(hex: startHex), Color(hex: endHex)]
    }
    
    // Helper method to create background gradient
    static func backgroundGradient(for quote: Quote) -> LinearGradient {
        LinearGradient(
            colors: gradientColors(from: quote),
            startPoint: Gradient.startPoint,
            endPoint: Gradient.endPoint
        )
    }
    
    // Helper method to truncate quote text for small widget
    static func truncatedQuote(_ text: String) -> String {
        return text.count > TextLimits.smallQuoteTruncation 
            ? String(text.prefix(TextLimits.smallQuoteTruncation - 3)) + TextLimits.smallQuoteTruncationSuffix 
            : text
    }
    
    // Helper method to format date
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.datePattern
        return formatter.string(from: date)
    }
} 