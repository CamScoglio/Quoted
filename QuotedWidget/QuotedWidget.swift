//
//  QuotedWidget.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import WidgetKit
import SwiftUI
import Intents
import AppIntents
import Supabase

// MARK: - Widget Timeline Provider
struct QuotedWidgetProvider: TimelineProvider {
    private let supabase = SupabaseManager.shared
    
    func placeholder(in context: Context) -> QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "The only way to do great work is to love what you do.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Steve Jobs",
                    profession: "Entrepreneur",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Motivation",
                    icon: "lightbulb.fill",
                    themeColor: "#667eea",
                    createdAt: Date()
                )
            ),
            isAuthenticated: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuotedWidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotedWidgetEntry>) -> Void) {
        Task {
            if context.isPreview {
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .never)
                completion(timeline)
                return
            }
            
            // Check authentication using shared state
            guard supabase.isUserAuthenticated() else {
                print("🔴 [Widget] User not authenticated - showing sign-in prompt")
                let entry = createUnauthenticatedEntry()
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
                completion(timeline)
                return
            }
            
            print("🟢 [Widget] User authenticated")
            
            do {
                // Get user's daily quote, creating one if needed
                let dailyQuote: DailyQuote
                if let existingQuote = try await supabase.getUserDailyQuote() {
                    print("🟢 [Widget] Found existing quote for today")
                    dailyQuote = existingQuote
                } else {
                    print("🟡 [Widget] No quote for today, assigning new one")
                    dailyQuote = try await supabase.assignRandomQuoteToUser()
                }
                
                let entry = QuotedWidgetEntry(
                    date: Date(),
                    dailyQuote: dailyQuote,
                    isAuthenticated: true
                )
                
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(24 * 60 * 60)))
                completion(timeline)
                
            } catch {
                print("🔴 [Widget] Error loading quote: \(error)")
                let entry = createErrorEntry(error: error)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60)))
                completion(timeline)
            }
        }
    }
    
    /// Create an entry for unauthenticated users
    private func createUnauthenticatedEntry() -> QuotedWidgetEntry {
        return QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "Sign in to the app to see your daily quote",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                isFeatured: false,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Quoted App",
                    profession: "",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Authentication",
                    icon: "person.fill",
                    themeColor: "#667eea",
                    createdAt: Date()
                )
            ),
            isAuthenticated: false
        )
    }
    
    /// Create an entry for error states
    private func createErrorEntry(error: Error) -> QuotedWidgetEntry {
        return QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "Unable to load your daily quote. Please try again later.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                isFeatured: false,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Error",
                    profession: "",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Error",
                    icon: "exclamationmark.circle",
                    themeColor: "#667eea",
                    createdAt: Date()
                )
            ),
            isAuthenticated: true
        )
    }
}

// MARK: - Widget Entry
struct QuotedWidgetEntry: TimelineEntry {
    let date: Date
    let dailyQuote: DailyQuote
    let isAuthenticated: Bool
}

// MARK: - Widget Views
struct QuotedWidgetSmallView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        VStack(spacing: WidgetStyles.Layout.Spacing.medium) {
            // Next button (only show for authenticated users)
            HStack {
                Spacer()
                if entry.isAuthenticated {
                    Button(intent: NextQuoteIntent()) {
                        HStack(spacing: WidgetStyles.Layout.Spacing.small) {
                            Text(WidgetStyles.Labels.nextButtonText)
                                .font(WidgetStyles.Typography.Small.buttonFont)
                                .fontWeight(WidgetStyles.Typography.Small.buttonFontWeight)
                            Image(systemName: WidgetStyles.IconNames.nextArrow)
                                .font(WidgetStyles.Typography.Icons.buttonIcon)
                        }
                        .foregroundColor(WidgetStyles.Colors.buttonText)
                        .padding(.horizontal, WidgetStyles.Layout.Button.horizontalPadding)
                        .padding(.vertical, WidgetStyles.Layout.Button.verticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: WidgetStyles.Layout.buttonCornerRadius)
                                .fill(WidgetStyles.Colors.buttonBackground)
                        )
                    }
                } else {
                    // Show disabled button for unauthenticated users
                    HStack(spacing: WidgetStyles.Layout.Spacing.small) {
                        Text("Sign In")
                            .font(WidgetStyles.Typography.Small.buttonFont)
                            .fontWeight(WidgetStyles.Typography.Small.buttonFontWeight)
                        Image(systemName: "person.fill")
                            .font(WidgetStyles.Typography.Icons.buttonIcon)
                    }
                    .foregroundColor(WidgetStyles.Colors.buttonText.opacity(0.6))
                    .padding(.horizontal, WidgetStyles.Layout.Button.horizontalPadding)
                    .padding(.vertical, WidgetStyles.Layout.Button.verticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: WidgetStyles.Layout.buttonCornerRadius)
                            .fill(WidgetStyles.Colors.buttonBackground.opacity(0.6))
                    )
                }
            }
            
            // Quote icon
            Image(systemName: entry.isAuthenticated ? WidgetStyles.IconNames.quote : "person.fill")
                .font(WidgetStyles.Typography.Icons.smallQuoteIcon)
                .foregroundColor(WidgetStyles.Colors.buttonText)
            
            // Truncated quote text
            Text(WidgetStyles.truncatedQuote(entry.dailyQuote.quoteText))
                .font(WidgetStyles.Typography.Small.quoteFont)
                .fontWeight(WidgetStyles.Typography.Small.quoteFontWeight)
                .foregroundColor(WidgetStyles.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(WidgetStyles.TextLimits.smallQuoteLineLimit)
            
            Spacer()
            
            // Author name
            Text("\(WidgetStyles.Labels.authorPrefix)\(entry.dailyQuote.authors.name)")
                .font(WidgetStyles.Typography.Small.authorFont)
                .fontWeight(WidgetStyles.Typography.Small.authorFontWeight)
                .foregroundColor(WidgetStyles.Colors.secondaryText)
                .lineLimit(WidgetStyles.TextLimits.authorLineLimit)
        }
        .padding(WidgetStyles.Layout.smallWidgetPadding)
        .clipShape(RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius))
        .containerBackground(for: .widget) {
            WidgetStyles.backgroundGradient(for: entry.dailyQuote)
        }
    }
}

struct QuotedWidgetMediumView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        HStack(spacing: WidgetStyles.Layout.Spacing.extraLarge) {
            VStack(alignment: .leading, spacing: WidgetStyles.Layout.Spacing.large) {
                // Next button
                HStack {
                    if entry.isAuthenticated {
                        Button(intent: NextQuoteIntent()) {
                            HStack(spacing: WidgetStyles.Layout.Spacing.small) {
                                Text(WidgetStyles.Labels.nextButtonText)
                                    .font(WidgetStyles.Typography.Medium.buttonFont)
                                    .fontWeight(WidgetStyles.Typography.Medium.buttonFontWeight)
                                Image(systemName: WidgetStyles.IconNames.nextArrow)
                                    .font(WidgetStyles.Typography.Icons.buttonIcon)
                            }
                            .foregroundColor(WidgetStyles.Colors.buttonText)
                            .padding(.horizontal, WidgetStyles.Layout.Button.horizontalPadding)
                            .padding(.vertical, WidgetStyles.Layout.Button.verticalPadding)
                            .background(
                                RoundedRectangle(cornerRadius: WidgetStyles.Layout.buttonCornerRadius)
                                    .fill(WidgetStyles.Colors.buttonBackground)
                            )
                        }
                    } else {
                        // Show sign-in prompt for unauthenticated users
                        HStack(spacing: WidgetStyles.Layout.Spacing.small) {
                            Text("Sign In to App")
                                .font(WidgetStyles.Typography.Medium.buttonFont)
                                .fontWeight(WidgetStyles.Typography.Medium.buttonFontWeight)
                            Image(systemName: "person.fill")
                                .font(WidgetStyles.Typography.Icons.buttonIcon)
                        }
                        .foregroundColor(WidgetStyles.Colors.buttonText.opacity(0.6))
                        .padding(.horizontal, WidgetStyles.Layout.Button.horizontalPadding)
                        .padding(.vertical, WidgetStyles.Layout.Button.verticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: WidgetStyles.Layout.buttonCornerRadius)
                                .fill(WidgetStyles.Colors.buttonBackground.opacity(0.6))
                        )
                    }
                    
                    Spacer()
                    
                    Image(systemName: entry.isAuthenticated ? WidgetStyles.IconNames.quote : "person.fill")
                        .font(WidgetStyles.Typography.Icons.mediumQuoteIcon)
                        .foregroundColor(WidgetStyles.Colors.secondaryText)
                }
                
                // Quote text
                Text(entry.dailyQuote.quoteText)
                    .font(WidgetStyles.Typography.Medium.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                    .lineLimit(WidgetStyles.TextLimits.mediumQuoteLineLimit)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Author info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(WidgetStyles.Labels.authorPrefix)\(entry.dailyQuote.authors.name)")
                        .font(WidgetStyles.Typography.Medium.authorFont)
                        .fontWeight(WidgetStyles.Typography.Medium.authorFontWeight)
                        .foregroundColor(WidgetStyles.Colors.primaryText)
                    
                    if !entry.dailyQuote.authors.profession.isEmpty {
                        Text(entry.dailyQuote.authors.profession)
                            .font(WidgetStyles.Typography.Medium.professionFont)
                            .foregroundColor(WidgetStyles.Colors.tertiaryText)
                    }
                }
            }
            .padding(WidgetStyles.Layout.mediumWidgetPadding)
            
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius))
        .containerBackground(for: .widget) {
            WidgetStyles.backgroundGradient(for: entry.dailyQuote)
        }
    }
}

struct QuotedWidgetLargeView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        VStack(spacing: WidgetStyles.Layout.Spacing.huge) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: WidgetStyles.Layout.Spacing.small) {
                    Text(entry.isAuthenticated ? WidgetStyles.Labels.dailyQuoteHeader : "Welcome to Quoted")
                        .font(WidgetStyles.Typography.Large.headerFont)
                        .fontWeight(WidgetStyles.Typography.Large.headerFontWeight)
                        .foregroundColor(WidgetStyles.Colors.secondaryText)
                    
                    Text(WidgetStyles.formatDate(entry.date))
                        .font(WidgetStyles.Typography.Large.dateFont)
                        .foregroundColor(WidgetStyles.Colors.quaternaryText)
                }
                
                Spacer()
                
                // Next button (only for authenticated users)
                if entry.isAuthenticated {
                    Button(intent: NextQuoteIntent()) {
                        HStack(spacing: WidgetStyles.Layout.Spacing.small + 2) {
                            Text(WidgetStyles.Labels.nextButtonText)
                                .font(WidgetStyles.Typography.Large.buttonFont)
                                .fontWeight(WidgetStyles.Typography.Large.buttonFontWeight)
                            Image(systemName: WidgetStyles.IconNames.nextArrow)
                                .font(WidgetStyles.Typography.Icons.buttonIcon)
                        }
                        .foregroundColor(WidgetStyles.Colors.buttonText)
                        .padding(.horizontal, WidgetStyles.Layout.Button.largeHorizontalPadding)
                        .padding(.vertical, WidgetStyles.Layout.Button.largeVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: WidgetStyles.Layout.largeButtonCornerRadius)
                                .fill(WidgetStyles.Colors.buttonBackground)
                        )
                    }
                } else {
                    // Show sign-in button for unauthenticated users
                    HStack(spacing: WidgetStyles.Layout.Spacing.small + 2) {
                        Text("Sign In")
                            .font(WidgetStyles.Typography.Large.buttonFont)
                            .fontWeight(WidgetStyles.Typography.Large.buttonFontWeight)
                        Image(systemName: "person.fill")
                            .font(WidgetStyles.Typography.Icons.buttonIcon)
                    }
                    .foregroundColor(WidgetStyles.Colors.buttonText.opacity(0.6))
                    .padding(.horizontal, WidgetStyles.Layout.Button.largeHorizontalPadding)
                    .padding(.vertical, WidgetStyles.Layout.Button.largeVerticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: WidgetStyles.Layout.largeButtonCornerRadius)
                            .fill(WidgetStyles.Colors.buttonBackground.opacity(0.6))
                    )
                }
            }
            
            Spacer()
            
            // Quote content
            VStack(spacing: WidgetStyles.Layout.Spacing.extraLarge) {
                // Quote mark
                Image(systemName: entry.isAuthenticated ? WidgetStyles.IconNames.quote : "person.fill")
                    .font(WidgetStyles.Typography.Icons.largeQuoteIcon)
                    .foregroundColor(WidgetStyles.Colors.secondaryText)
                
                // Quote text
                Text(entry.dailyQuote.quoteText)
                    .font(WidgetStyles.Typography.Large.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(WidgetStyles.TextLimits.largeQuoteLineLimit)
                    .lineSpacing(WidgetStyles.TextLimits.quoteLineSpacing)
            }
            
            Spacer()
            
            // Author section
            VStack(spacing: WidgetStyles.Layout.Spacing.medium) {
                Text("\(WidgetStyles.Labels.authorPrefix)\(entry.dailyQuote.authors.name)")
                    .font(WidgetStyles.Typography.Large.authorFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                
                if !entry.dailyQuote.authors.profession.isEmpty {
                    Text(entry.dailyQuote.authors.profession)
                        .font(WidgetStyles.Typography.Large.professionFont)
                        .foregroundColor(WidgetStyles.Colors.secondaryText)
                }
            }
        }
        .padding(WidgetStyles.Layout.largeWidgetPadding)
        .clipShape(RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius))
        .containerBackground(for: .widget) {
            WidgetStyles.backgroundGradient(for: entry.dailyQuote)
        }
    }
}

// MARK: - Main Widget View
struct QuotedWidgetEntryView: View {
    var entry: QuotedWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            QuotedWidgetSmallView(entry: entry)
        case .systemMedium:
            QuotedWidgetMediumView(entry: entry)
        case .systemLarge:
            QuotedWidgetLargeView(entry: entry)
        default:
            QuotedWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct QuotedWidget: Widget {
    let kind: String = "QuotedWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotedWidgetProvider()) { entry in
            QuotedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Get inspired with a new quote every day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Extensions
// Color extension is now in Shared/Extensions/Color+Extensions.swift

// MARK: - Preview
#if DEBUG
struct QuotedWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                id: UUID(),
                quoteText: "The only way to do great work is to love what you do.",
                authorId: UUID(),
                categoryId: UUID(),
                designTheme: "minimal",
                backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                isFeatured: true,
                createdAt: Date(),
                authors: Author(
                    id: UUID(),
                    name: "Steve Jobs",
                    profession: "Entrepreneur",
                    bio: nil,
                    imageUrl: nil
                ),
                categories: Category(
                    id: UUID(),
                    name: "Motivation",
                    icon: "lightbulb.fill",
                    themeColor: "#667eea",
                    createdAt: Date()
                )
            ),
            isAuthenticated: false
        )
        
        Group {
            QuotedWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            QuotedWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            QuotedWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}
#endif
