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
struct QuotedWidgetProvider: AppIntentTimelineProvider {
    
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
            isAuthenticated: true
        )
    }
    
    func snapshot(for configuration: NextQuoteIntent, in context: Context) async -> QuotedWidgetEntry {
        print("🔵 [Widget Snapshot] Starting snapshot generation")
        
        if context.isPreview {
            return placeholder(in: context)
        }
        
        // Check auth using shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.Scoglio.Quoted")
        let isAuth = sharedDefaults?.bool(forKey: "isAuthenticated") ?? false
        
        guard isAuth else {
            print("🔴 [Widget Snapshot] User not authenticated")
            return QuotedWidgetEntry(
                date: Date(),
                dailyQuote: nil,
                isAuthenticated: false
            )
        }
        
        print("🟢 [Widget Snapshot] User authenticated - getting daily quote")
        do {
            let dailyQuote = try await SupabaseService.shared.getUserDailyQuote()
            print("🟢 [Widget Snapshot] Got daily quote: \(dailyQuote?.quoteText ?? "nil")")
            return QuotedWidgetEntry(
                date: Date(),
                dailyQuote: dailyQuote,
                isAuthenticated: true
            )
        } catch {
            print("🔴 [Widget Snapshot] Error: \(error)")
            return QuotedWidgetEntry(
                date: Date(),
                dailyQuote: nil,
                isAuthenticated: true
            )
        }
    }

    func timeline(for configuration: NextQuoteIntent, in context: Context) async -> Timeline<QuotedWidgetEntry> {
        print("🔵 [Widget Timeline] Starting timeline generation")
        
        if context.isPreview {
            let entry = placeholder(in: context)
            return Timeline(entries: [entry], policy: .never)
        }
        
        // Check auth using shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.Scoglio.Quoted")
        let isAuth = sharedDefaults?.bool(forKey: "isAuthenticated") ?? false
        let userId = sharedDefaults?.string(forKey: "currentUserId")
        print("🔍 [Widget Timeline] Auth check - isAuth: \(isAuth), userId: \(userId ?? "nil")")
        
        guard isAuth else {
            print("🔴 [Widget Timeline] User not authenticated")
            let entry = QuotedWidgetEntry(
                date: Date(),
                dailyQuote: nil,
                isAuthenticated: false
            )
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        }
        
        print("🟢 [Widget Timeline] User authenticated")
        
        // First try to get quote from shared storage (fast path)
        if let cachedQuote = SupabaseService.shared.getQuoteFromSharedStorage() {
            print("🟢 [Widget Timeline] Using cached quote: \(cachedQuote.quoteText)")
            print("🔍 [Widget Timeline] Quote ID: \(cachedQuote.id), Author: \(cachedQuote.authors.name)")
            
            // Debug: Check shared UserDefaults directly
            let lastUpdated = sharedDefaults?.double(forKey: "quoteLastUpdated") ?? 0
            let lastUpdatedDate = Date(timeIntervalSince1970: lastUpdated)
            print("🔍 [Widget Timeline] Last updated timestamp: \(lastUpdated) (\(lastUpdatedDate))")
            
            // Debug: Check raw shared storage data
            if let rawData = sharedDefaults?.data(forKey: "currentDailyQuote") {
                print("🔍 [Widget Timeline] Raw shared data exists, size: \(rawData.count) bytes")
            } else {
                print("🔴 [Widget Timeline] No raw shared data found!")
            }
            
            let entry = QuotedWidgetEntry(date: Date(), dailyQuote: cachedQuote, isAuthenticated: true)
            let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
            print("🟢 [Widget Timeline] Timeline set to refresh at: \(tomorrow)")
            return Timeline(entries: [entry], policy: .after(tomorrow))
        }
        
        // If no cached quote, try to get from database (this may fail due to RLS)
        do {
            let dailyQuote = try await SupabaseService.shared.getUserDailyQuote()
            print("🟢 [Widget Timeline] Successfully got quote from DB: \(dailyQuote?.quoteText ?? "nil")")
            let entry = QuotedWidgetEntry(date: Date(), dailyQuote: dailyQuote, isAuthenticated: true)
            let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
            print("🟢 [Widget Timeline] Timeline set to refresh at: \(tomorrow)")
            return Timeline(entries: [entry], policy: .after(tomorrow))
        } catch {
            print("🔴 [Widget Timeline] Error getting quote from DB: \(error)")
            print("🟡 [Widget Timeline] Requesting app to fetch new quote")
            
            // Request the main app to fetch data
            sharedDefaults?.set(true, forKey: "widgetNeedsData")
            SupabaseService.shared.triggerSync()
            
            let entry = QuotedWidgetEntry(date: Date(), dailyQuote: nil, isAuthenticated: true)
            // Retry more frequently when we need data
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5 * 60)))
        }
    }
}

// MARK: - Widget Entry
struct QuotedWidgetEntry: TimelineEntry {
    let date: Date
    let dailyQuote: DailyQuote?
    let isAuthenticated: Bool
    
    // Convenience initializer for authenticated entries with quote
    init(date: Date, dailyQuote: DailyQuote?, isAuthenticated: Bool = true) {
        self.date = date
        self.dailyQuote = dailyQuote
        self.isAuthenticated = isAuthenticated
    }
    
    // Computed property to get a safe daily quote (for UI display)
    var safeDailyQuote: DailyQuote {
        return dailyQuote ?? DailyQuote(
            id: UUID(),
            quoteText: isAuthenticated ? "Unable to load your daily quote" : "Sign in to the app to see your daily quotes",
            authorId: UUID(),
            categoryId: UUID(),
            designTheme: "minimal",
            backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
            isFeatured: true,
            createdAt: Date(),
            authors: Author(
                id: UUID(),
                name: isAuthenticated ? "Quoted" : "Welcome",
                profession: "",
                bio: nil,
                imageUrl: nil
            ),
            categories: Category(
                id: UUID(),
                name: "System",
                icon: "person.fill",
                themeColor: "#667eea",
                createdAt: Date()
            )
        )
    }
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
            Text(WidgetStyles.truncatedQuote(entry.safeDailyQuote.quoteText))
                .font(WidgetStyles.Typography.Small.quoteFont)
                .fontWeight(WidgetStyles.Typography.Small.quoteFontWeight)
                .foregroundColor(WidgetStyles.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(WidgetStyles.TextLimits.smallQuoteLineLimit)
            
            Spacer()
            
            // Author name
            Text("\(WidgetStyles.Labels.authorPrefix)\(entry.safeDailyQuote.authors.name)")
                .font(WidgetStyles.Typography.Small.authorFont)
                .fontWeight(WidgetStyles.Typography.Small.authorFontWeight)
                .foregroundColor(WidgetStyles.Colors.secondaryText)
                .lineLimit(WidgetStyles.TextLimits.authorLineLimit)
        }
        .padding(WidgetStyles.Layout.smallWidgetPadding)
        .clipShape(RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius))
        .containerBackground(for: .widget) {
            WidgetStyles.backgroundGradient(for: entry.safeDailyQuote)
        }
        .id(entry.dailyQuote?.id ?? UUID())
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
                Text(entry.safeDailyQuote.quoteText)
                    .font(WidgetStyles.Typography.Medium.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                    .lineLimit(WidgetStyles.TextLimits.mediumQuoteLineLimit)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Author info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(WidgetStyles.Labels.authorPrefix)\(entry.safeDailyQuote.authors.name)")
                        .font(WidgetStyles.Typography.Medium.authorFont)
                        .fontWeight(WidgetStyles.Typography.Medium.authorFontWeight)
                        .foregroundColor(WidgetStyles.Colors.primaryText)
                    
                    if !entry.safeDailyQuote.authors.profession.isEmpty {
                        Text(entry.safeDailyQuote.authors.profession)
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
            WidgetStyles.backgroundGradient(for: entry.safeDailyQuote)
        }
        .id(entry.dailyQuote?.id ?? UUID())
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
                Text(entry.safeDailyQuote.quoteText)
                    .font(WidgetStyles.Typography.Large.quoteFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(WidgetStyles.TextLimits.largeQuoteLineLimit)
                    .lineSpacing(WidgetStyles.TextLimits.quoteLineSpacing)
            }
            
            Spacer()
            
            // Author section
            VStack(spacing: WidgetStyles.Layout.Spacing.medium) {
                Text("\(WidgetStyles.Labels.authorPrefix)\(entry.safeDailyQuote.authors.name)")
                    .font(WidgetStyles.Typography.Large.authorFont)
                    .foregroundColor(WidgetStyles.Colors.primaryText)
                
                if !entry.safeDailyQuote.authors.profession.isEmpty {
                    Text(entry.safeDailyQuote.authors.profession)
                        .font(WidgetStyles.Typography.Large.professionFont)
                        .foregroundColor(WidgetStyles.Colors.secondaryText)
                }
            }
        }
        .padding(WidgetStyles.Layout.largeWidgetPadding)
        .clipShape(RoundedRectangle(cornerRadius: WidgetStyles.Layout.widgetCornerRadius))
        .containerBackground(for: .widget) {
            WidgetStyles.backgroundGradient(for: entry.safeDailyQuote)
        }
        .id(entry.dailyQuote?.id ?? UUID())
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
        AppIntentConfiguration(kind: kind, intent: NextQuoteIntent.self, provider: QuotedWidgetProvider()) { entry in
            QuotedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Get inspired with a new quote every day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

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
            isAuthenticated: true
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
