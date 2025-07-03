//
//  QuotedWidget.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import WidgetKit
import SwiftUI
import Supabase

// MARK: - Widget Timeline Provider
struct QuotedWidgetProvider: TimelineProvider {
    
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
    
    func getSnapshot(in context: Context, completion: @escaping (QuotedWidgetEntry) -> ()) {
        print("🔵 [Widget Snapshot] Starting snapshot generation")
        
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        // Check auth using shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.Scoglio.Quoted")
        let isAuth = sharedDefaults?.bool(forKey: "isAuthenticated") ?? false
        
        guard isAuth else {
            print("🔴 [Widget Snapshot] User not authenticated")
            completion(QuotedWidgetEntry(
                date: Date(),
                dailyQuote: nil,
                isAuthenticated: false
            ))
            return
        }
        
        
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotedWidgetEntry>) -> ()) {
        print("🔵 [Widget Timeline] Starting timeline generation")
        
        if context.isPreview {
            let entry = placeholder(in: context)
            completion(Timeline(entries: [entry], policy: .never))
            return
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
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
            return
        }
        
        print("🟢 [Widget Timeline] User authenticated")
    
        Task {
            do {
                let dailyQuote = try await SupabaseService.shared.getUserDailyQuote()
                print("🟢 [Widget Timeline] Successfully got quote from DB: \(dailyQuote?.quoteText ?? "nil")")
                let entry = QuotedWidgetEntry(date: Date(), dailyQuote: dailyQuote, isAuthenticated: true)
                let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
                print("🟢 [Widget Timeline] Timeline set to refresh at: \(tomorrow)")
                completion(Timeline(entries: [entry], policy: .after(tomorrow)))
            } catch {
                print("🔴 [Widget Timeline] Error getting quote from DB: \(error)")
                print("🟡 [Widget Timeline] Requesting app to fetch new quote")
                
                // Request the main app to fetch data
                sharedDefaults?.set(true, forKey: "widgetNeedsData")
                SupabaseService.shared.triggerSync()
                
                let entry = QuotedWidgetEntry(date: Date(), dailyQuote: nil, isAuthenticated: true)
                // Retry more frequently when we need data
                completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5 * 60))))
            }
            return
        }
    }
}

// MARK: - Widget Entry
struct QuotedWidgetEntry: TimelineEntry {
    let date: Date
    let dailyQuote: DailyQuote?
    let isAuthenticated: Bool
    
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
            // Quote icon
            Image(systemName: entry.isAuthenticated ? WidgetStyles.IconNames.quote : "person.fill")
                .font(WidgetStyles.Typography.Icons.smallQuoteIcon)
                .foregroundColor(WidgetStyles.Colors.secondaryText)
            
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
                // Header with quote icon
                HStack {
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
        StaticConfiguration(kind: kind, provider: QuotedWidgetProvider()) { entry in
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
