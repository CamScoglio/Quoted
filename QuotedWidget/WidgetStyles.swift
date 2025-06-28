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

// MARK: - Previews
#if DEBUG
import WidgetKit

// Simple style testing previews that work independently
@available(iOS 14.0, *)
struct WidgetStylesPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // Color Palette Preview
            VStack(spacing: 12) {
                Text("Widget Color Palette")
                    .font(.headline)
                    .padding()
                
                HStack {
                    ColorSwatch(color: WidgetStyles.Colors.primaryText, name: "Primary")
                    ColorSwatch(color: WidgetStyles.Colors.secondaryText, name: "Secondary")
                    ColorSwatch(color: WidgetStyles.Colors.tertiaryText, name: "Tertiary")
                }
                
                HStack {
                    ColorSwatch(color: WidgetStyles.Colors.buttonBackground, name: "Button BG")
                    ColorSwatch(color: WidgetStyles.Colors.buttonText, name: "Button Text")
                }
            }
            .padding()
            .previewDisplayName("Color Palette")
            
            // Typography Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography Styles")
                    .font(.headline)
                    .padding(.bottom)
                
                Text("Small Widget Quote")
                    .font(WidgetStyles.Typography.Small.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                
                Text("Medium Widget Quote")
                    .font(WidgetStyles.Typography.Medium.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                
                Text("Large Widget Quote")
                    .font(WidgetStyles.Typography.Large.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                
                Text("— Author Name")
                    .font(WidgetStyles.Typography.Small.authorFont)
                    .foregroundColor(WidgetStyles.Colors.secondaryText)
            }
            .padding()
            .previewDisplayName("Typography")
            
            // Gradient Preview
            VStack(spacing: 12) {
                Text("Gradient Styles")
                    .font(.headline)
                    .padding()
                
                RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 60)
                    .overlay(
                        Text("Blue Purple")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                
                RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#4facfe"), Color(hex: "#00f2fe")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 60)
                    .overlay(
                        Text("Blue Cyan")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }
            .padding()
            .previewDisplayName("Gradients")
        }
    }
}

// Helper view for color swatches
struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 50, height: 50)
            Text(name)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }
}

// Live Widget Previews - These match the actual built widgets exactly
@available(iOS 14.0, *)
struct LiveWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small Widget - Exact match to built widget
            QuotedWidgetSmallView(entry: sampleEntrySmall)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget - Live")
            
            // Medium Widget - Exact match to built widget  
            QuotedWidgetMediumView(entry: sampleEntryMedium)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget - Live")
            
            // Large Widget - Exact match to built widget
            QuotedWidgetLargeView(entry: sampleEntryLarge)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget - Live")
        }
    }
    
    // Sample data that you can edit to see live changes
    static var sampleEntrySmall: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "Be yourself; everyone else is already taken.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Oscar Wilde",
                    profession: "Writer",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Self",
                    icon: "person.fill",
                    themeColor: "#667eea",
                    createdAt: Date()
                )
            )
        )
    }
    
    static var sampleEntryMedium: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "The only way to do great work is to love what you do. Success comes to those who dare to begin.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#4facfe", "end": "#00f2fe"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Steve Jobs",
                    profession: "Entrepreneur & Innovator",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Motivation",
                    icon: "star.fill",
                    themeColor: "#4facfe",
                    createdAt: Date()
                )
            )
        )
    }
    
    static var sampleEntryLarge: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "The future belongs to those who believe in the beauty of their dreams and are willing to work tirelessly to make them a reality.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#fa709a", "end": "#fee140"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Eleanor Roosevelt",
                    profession: "Former First Lady",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Dreams",
                    icon: "star.fill",
                    themeColor: "#fa709a",
                    createdAt: Date()
                )
            )
        )
    }
}

// MARK: - Live Style Editor Previews
// Edit these values to see INSTANT changes in your widgets!
@available(iOS 14.0, *)
struct LiveStyleEditor: PreviewProvider {
    static var previews: some View {
        Group {
            // 🎨 EDIT THESE VALUES TO SEE LIVE CHANGES! 🎨
            
            // Small Widget with Editable Styles
            QuotedWidgetSmallView(entry: editableSmallEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("🎨 Small - Edit Me!")
            
            // Medium Widget with Editable Styles
            QuotedWidgetMediumView(entry: editableMediumEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("🎨 Medium - Edit Me!")
            
            // Large Widget with Editable Styles
            QuotedWidgetLargeView(entry: editableLargeEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("🎨 Large - Edit Me!")
        }
    }
    
    // 🔥 EDIT THESE SAMPLE ENTRIES TO TEST DIFFERENT STYLES! 🔥
    
    static var editableSmallEntry: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                // 📝 EDIT THIS QUOTE TEXT:
                quoteText: "Life is what happens when you're busy making other plans.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                // 🎨 EDIT THESE GRADIENT COLORS (hex format):
                backgroundGradient: ["start": "#ff9a9e", "end": "#fecfef"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    // 📝 EDIT AUTHOR NAME:
                    name: "John Lennon",
                    // 📝 EDIT PROFESSION:
                    profession: "Musician",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    // 📝 EDIT CATEGORY:
                    name: "Life",
                    icon: "heart.fill",
                    themeColor: "#ff9a9e",
                    createdAt: Date()
                )
            )
        )
    }
    
    static var editableMediumEntry: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                // 📝 EDIT THIS QUOTE TEXT:
                quoteText: "Innovation distinguishes between a leader and a follower. The key is to embrace change.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                // 🎨 EDIT THESE GRADIENT COLORS:
                backgroundGradient: ["start": "#a8edea", "end": "#fed6e3"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    // 📝 EDIT AUTHOR NAME:
                    name: "Steve Jobs",
                    // 📝 EDIT PROFESSION:
                    profession: "Visionary & CEO",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    // 📝 EDIT CATEGORY:
                    name: "Innovation",
                    icon: "lightbulb.fill",
                    themeColor: "#a8edea",
                    createdAt: Date()
                )
            )
        )
    }
    
    static var editableLargeEntry: QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                // 📝 EDIT THIS QUOTE TEXT:
                quoteText: "The only impossible journey is the one you never begin. Every expert was once a beginner, and every pro was once an amateur.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                // 🎨 EDIT THESE GRADIENT COLORS:
                backgroundGradient: ["start": "#ffecd2", "end": "#fcb69f"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    // 📝 EDIT AUTHOR NAME:
                    name: "Tony Robbins",
                    // 📝 EDIT PROFESSION:
                    profession: "Motivational Speaker",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    // 📝 EDIT CATEGORY:
                    name: "Growth",
                    icon: "arrow.up.circle.fill",
                    themeColor: "#ffecd2",
                    createdAt: Date()
                )
            )
        )
    }
}

#endif
