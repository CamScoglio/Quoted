import SwiftUI

/*
 🎨 WIDGET DESIGN CUSTOMIZATION GUIDE 🎨
 
 ═══════════════════════════════════════════════════════════════════════════════
 
 📍 QUICK DESIGN CHANGES:
 
 🎨 COLORS:
    • Colors.primaryText        → Main quote text color
    • Colors.buttonBackground   → "Next" button background
    • Colors.fallbackGradient*  → Default gradient when quote has none
 
 ✍️ FONTS:
    • Typography.*.quoteFont    → Quote text size/style
    • Typography.*.authorFont   → Author name size/style
    • Typography.*.buttonFont   → Button text size/style
 
 📐 LAYOUT:
    • Layout.*WidgetPadding     → Space between widget edge and content
    • Layout.Spacing.*          → Gaps between elements
    • Layout.*CornerRadius      → How rounded corners are
 
 🎯 POSITIONING:
    • Layout.Button.*Padding    → Space inside buttons
    • TextLimits.*LineLimit     → How many lines of text to show
    • Gradient.startPoint/endPoint → Gradient direction
 
 🏷️ TEXT & ICONS:
    • Labels.nextButtonText     → Button text ("Next", "→", etc.)
    • IconNames.quote          → Quote bubble icon
    • IconNames.nextArrow      → Button arrow icon
 
 ═══════════════════════════════════════════════════════════════════════════════
 
 💡 PRO TIPS:
 • Use the "LiveStyleEditor" previews to see changes instantly!
 • Change gradient colors in the preview sample data
 • Test with different quote lengths using the editable entries
 • Font options: .caption, .caption2, .footnote, .body, .title3, etc.
 • Icon options: SF Symbols (quote.opening, chevron.right, star.fill, etc.)
 
 ═══════════════════════════════════════════════════════════════════════════════
*/

// MARK: - Widget Styles Configuration
// 🎨 EDIT THIS FILE TO CUSTOMIZE YOUR WIDGET DESIGN! 🎨
struct WidgetStyles {
    
    // MARK: - Colors 🎨
    // ✏️ EDIT THESE TO CHANGE TEXT AND BUTTON COLORS
    struct Colors {
        // 📝 TEXT COLORS - Changes the color of all text elements
        static let primaryText = Color.white           // 🔸 Main quote text color
        static let secondaryText = Color.white.opacity(0.8)    // 🔸 Author name color  
        static let tertiaryText = Color.white.opacity(0.7)     // 🔸 Headers & category text color
        static let quaternaryText = Color.white.opacity(0.6)   // 🔸 Date text color
        static let buttonText = Color.white.opacity(0.9)       // 🔸 "Next" button text color
        
        // 📝 BACKGROUND COLORS - Changes button and fallback colors
        static let buttonBackground = Color.white.opacity(0.2) // 🔸 "Next" button background color
        static let fallbackGradientStart = Color.blue          // 🔸 Backup gradient start (if quote has no gradient)
        static let fallbackGradientEnd = Color.purple          // 🔸 Backup gradient end (if quote has no gradient)
    }
    
    // MARK: - Typography ✍️
    // ✏️ EDIT THESE TO CHANGE FONT SIZES, WEIGHTS, AND STYLES
    struct Typography {
        
        // 📱 SMALL WIDGET FONTS - Changes text appearance in small widgets
        struct Small {
            static let quoteFont = Font.caption                    // 🔸 Quote text font size
            static let quoteFontWeight = Font.Weight.medium        // 🔸 Quote text boldness
            static let authorFont = Font.caption2                  // 🔸 Author name font size  
            static let authorFontWeight = Font.Weight.semibold     // 🔸 Author name boldness
            static let buttonFont = Font.caption2                  // 🔸 "Next" button font size
            static let buttonFontWeight = Font.Weight.semibold     // 🔸 "Next" button boldness
        }
        
        // 📱 MEDIUM WIDGET FONTS - Changes text appearance in medium widgets
        struct Medium {
            static let quoteFont = Font.system(size: 14, weight: .medium, design: .rounded)  // 🔸 Quote text font (size, weight, style)
            static let authorFont = Font.caption                   // 🔸 Author name font size
            static let authorFontWeight = Font.Weight.semibold     // 🔸 Author name boldness
            static let professionFont = Font.caption2              // 🔸 Author profession font size
            static let buttonFont = Font.caption2                  // 🔸 "Next" button font size
            static let buttonFontWeight = Font.Weight.semibold     // 🔸 "Next" button boldness
        }
        
        // 📱 LARGE WIDGET FONTS - Changes text appearance in large widgets
        struct Large {
            static let headerFont = Font.caption2                  // 🔸 "DAILY QUOTE" header font size
            static let headerFontWeight = Font.Weight.bold         // 🔸 "DAILY QUOTE" header boldness
            static let dateFont = Font.caption2                    // 🔸 Date font size
            static let quoteFont = Font.system(size: 16, weight: .medium, design: .rounded)  // 🔸 Quote text font (size, weight, style)
            static let authorFont = Font.system(size: 15, weight: .semibold)                 // 🔸 Author name font (size, weight)
            static let professionFont = Font.caption               // 🔸 Author profession font size
            static let buttonFont = Font.caption2                  // 🔸 "Next" button font size
            static let buttonFontWeight = Font.Weight.semibold     // 🔸 "Next" button boldness
        }
        
        // 🎯 ICON SIZES - Changes the size of quote icons and button arrows
        struct Icons {
            static let smallQuoteIcon = Font.title2                // 🔸 Quote bubble icon size (small widget)
            static let mediumQuoteIcon = Font.title3               // 🔸 Quote bubble icon size (medium widget)
            static let largeQuoteIcon = Font.largeTitle            // 🔸 Quote bubble icon size (large widget)
            static let buttonIcon = Font.caption2                  // 🔸 Arrow icon size in "Next" button
        }
    }
    
    // MARK: - Spacing & Layout 📐
    // ✏️ EDIT THESE TO CHANGE SPACING, PADDING, AND POSITIONING
    struct Layout {
        
        // 📦 WIDGET PADDING - Controls space between widget edge and content
        static let smallWidgetPadding: CGFloat = 12     // 🔸 Inner padding for small widgets
        static let mediumWidgetPadding: CGFloat = 16    // 🔸 Inner padding for medium widgets  
        static let largeWidgetPadding: CGFloat = 20     // 🔸 Inner padding for large widgets
        
        // 🔄 CORNER RADIUS - Controls how rounded the corners are
        static let widgetCornerRadius: CGFloat = 16     // 🔸 Widget corner roundness
        static let buttonCornerRadius: CGFloat = 0      // 🔸 Small/medium button corner roundness
        static let largeButtonCornerRadius: CGFloat = 10 // 🔸 Large button corner roundness
        
        // 📏 SPACING BETWEEN ELEMENTS - Controls gaps between text, buttons, etc.
        struct Spacing {
            static let small: CGFloat = 4               // 🔸 Tiny gaps (between button text & icon)
            static let medium: CGFloat = 8              // 🔸 Small gaps (between author & profession)
            static let large: CGFloat = 12              // 🔸 Medium gaps (between quote & author)
            static let extraLarge: CGFloat = 16         // 🔸 Large gaps (between major sections)
            static let huge: CGFloat = 20               // 🔸 Huge gaps (large widget sections)
        }
        
        // 🔘 BUTTON PADDING - Controls space inside the "Next" button
        struct Button {
            static let horizontalPadding: CGFloat = 0   // 🔸 Left/right space inside small/medium buttons
            static let verticalPadding: CGFloat = 0     // 🔸 Top/bottom space inside small/medium buttons
            static let largeHorizontalPadding: CGFloat = 0  // 🔸 Left/right space inside large buttons
            static let largeVerticalPadding: CGFloat = 0    // 🔸 Top/bottom space inside large buttons
        }
    }
    
    // MARK: - Text Limits 📝
    // ✏️ EDIT THESE TO CHANGE HOW MUCH TEXT IS SHOWN
    struct TextLimits {
        static let smallQuoteLineLimit = 3              // 🔸 Max lines of quote text in small widget
        static let mediumQuoteLineLimit = 4             // 🔸 Max lines of quote text in medium widget
        static let largeQuoteLineLimit = 6              // 🔸 Max lines of quote text in large widget
        static let authorLineLimit = 1                  // 🔸 Max lines for author name
        static let smallQuoteTruncation = 100           // 🔸 Max characters before "..." in small widget
        static let smallQuoteTruncationSuffix = "..."   // 🔸 Text added when quote is too long
        static let quoteLineSpacing: CGFloat = 2        // 🔸 Extra space between lines in quote text
    }
    
    // MARK: - Icons 🎯
    // ✏️ EDIT THESE TO CHANGE WHICH ICONS ARE USED
    struct IconNames {
        static let quote = "quote.bubble.fill"          // 🔸 Quote bubble icon (try: "quote.opening", "text.quote")
        static let nextArrow = "arrow.right"            // 🔸 Next button arrow (try: "chevron.right", "arrow.forward")
    }
    
    // MARK: - Gradient Configuration 🌈
    // ✏️ EDIT THESE TO CHANGE GRADIENT DIRECTION
    struct Gradient {
        static let startPoint = UnitPoint.topLeading    // 🔸 Where gradient starts (try: .top, .leading, .topTrailing)
        static let endPoint = UnitPoint.bottomTrailing  // 🔸 Where gradient ends (try: .bottom, .trailing, .bottomLeading)
    }
    
    // MARK: - Text Labels 🏷️
    // ✏️ EDIT THESE TO CHANGE BUTTON TEXT AND HEADERS
    struct Labels {
        static let dailyQuoteHeader = "DAILY QUOTE"     // 🔸 Header text in large widget
        static let nextButtonText = "Next"              // 🔸 Button text (try: "→", "New", "More")
        static let authorPrefix = "— "                  // 🔸 Text before author name (try: "by ", "~ ", "")
    }
    
    // MARK: - Date Formatting 📅
    // ✏️ EDIT THIS TO CHANGE DATE FORMAT
    struct DateFormat {
        static let datePattern = "MMMM d, yyyy"         // 🔸 Date format (try: "MMM d", "d/M/yyyy", "EEEE, MMM d")
    }
}

// MARK: - Style Helper Extensions
extension WidgetStyles {
    
    // Helper method to get gradient colors from quote data
    static func gradientColors(from dailyQuote: DailyQuote) -> [Color] {
        guard let gradient = dailyQuote.backgroundGradient,
              let startHex = gradient["start"],
              let endHex = gradient["end"] else {
            return [Colors.fallbackGradientStart, Colors.fallbackGradientEnd]
        }
        
        return [Color(hex: startHex), Color(hex: endHex)]
    }
    
    // Helper method to create background gradient
    static func backgroundGradient(for dailyQuote: DailyQuote) -> LinearGradient {
        LinearGradient(
            colors: gradientColors(from: dailyQuote),
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

/*
 ⚡ QUICK REFERENCE - MOST COMMON DESIGN CHANGES ⚡
 
 🎨 CHANGE COLORS:
 ┌─────────────────────────────────────────────────────────────┐
 │ Colors.primaryText = Color.black                            │  ← Quote text color
 │ Colors.buttonBackground = Color.blue.opacity(0.3)          │  ← Button background
 │ Colors.fallbackGradientStart = Color.red                   │  ← Default gradient start
 │ Colors.fallbackGradientEnd = Color.orange                  │  ← Default gradient end
 └─────────────────────────────────────────────────────────────┘
 
 ✍️ CHANGE FONT SIZES:
 ┌─────────────────────────────────────────────────────────────┐
 │ Typography.Large.quoteFont = Font.system(size: 18)         │  ← Large widget quote size
 │ Typography.Medium.quoteFont = Font.system(size: 16)        │  ← Medium widget quote size
 │ Typography.Small.quoteFont = Font.body                     │  ← Small widget quote size
 └─────────────────────────────────────────────────────────────┘
 
 📐 CHANGE SPACING:
 ┌─────────────────────────────────────────────────────────────┐
 │ Layout.largeWidgetPadding = 30                             │  ← More space around content
 │ Layout.Spacing.large = 20                                  │  ← Bigger gaps between elements
 │ Layout.widgetCornerRadius = 20                             │  ← More rounded corners
 └─────────────────────────────────────────────────────────────┘
 
 🏷️ CHANGE TEXT & ICONS:
 ┌─────────────────────────────────────────────────────────────┐
 │ Labels.nextButtonText = "→"                                │  ← Arrow instead of "Next"
 │ Labels.authorPrefix = "by "                                │  ← "by Author" instead of "— Author"
 │ IconNames.quote = "quote.opening"                          │  ← Different quote icon
 │ IconNames.nextArrow = "chevron.right"                      │  ← Different arrow icon
 └─────────────────────────────────────────────────────────────┘
 
 🎯 CHANGE BUTTON POSITION (in widget views):
 ┌─────────────────────────────────────────────────────────────┐
 │ Move "Button(intent: NextQuoteIntent())" to different      │  ← Reposition the Next button
 │ location in the VStack/HStack structure                    │  
 └─────────────────────────────────────────────────────────────┘
 
 */

#endif
