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
    private let supabase = SupabaseManager.shared.client
    private let sharedManager = SharedQuoteManager.shared
    
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
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuotedWidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotedWidgetEntry>) -> Void) {
        print("🟢 Widget Timeline: getTimeline called!")
        print("🟢 Widget Timeline: Context isPreview: \(context.isPreview)")
        
        Task {
            do {
                let dailyQuote: DailyQuote
                
                if context.isPreview {
                    print("🟢 Widget Timeline: Using placeholder for preview")
                    // Use placeholder for preview
                    dailyQuote = placeholder(in: context).dailyQuote
                } else {
                    // First, try to get the shared quote for consistency
                    if let sharedQuote = sharedManager.getCurrentQuote(),
                       !sharedManager.shouldFetchNewQuote() {
                        print("🔄 Widget Timeline: Using shared quote for consistency")
                        dailyQuote = sharedQuote
                    } else {
                        print("🟢 Widget Timeline: Fetching new quote from Supabase...")
                        // Get a new quote and save it for consistency
                        dailyQuote = try await getRandomQuote()
                        sharedManager.saveCurrentQuote(dailyQuote)
                        print("🟢 Widget Timeline: Successfully fetched and saved quote: '\(dailyQuote.quoteText.prefix(50))...'")
                        print("🟢 Widget Timeline: Quote author: \(dailyQuote.authors.name)")
                    }
                }
                
                let entry = QuotedWidgetEntry(date: Date(), dailyQuote: dailyQuote)
                
                // Set next refresh for 24 hours from now to maintain daily update cycle
                let nextRefresh = Date().addingTimeInterval(24 * 60 * 60)
                
                // Use .atEnd policy to allow manual refreshes via the Next button
                let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
                print("🟢 Widget Timeline: Timeline created successfully, calling completion")
                completion(timeline)
                
            } catch {
                print("🔴 Widget Timeline: Error occurred: \(error)")
                // Fallback to placeholder on error
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))) // Retry in 1 hour
                print("🟢 Widget Timeline: Using fallback placeholder due to error")
                completion(timeline)
            }
        }
    }
    
    private func getRandomQuote() async throws -> DailyQuote {
        print("🟡 getRandomQuote: Starting Supabase query...")
        
        // First, get the total count of quotes
        let countResponse = try await supabase
            .from("quotes")
            .select("id", head: true, count: .exact)
            .execute()
        
        guard let totalCount = countResponse.count, totalCount > 0 else {
            print("🔴 getRandomQuote: No quotes found in database!")
            throw QuoteServiceError.noQuotesFound
        }
        
        print("🟡 getRandomQuote: Found \(totalCount) total quotes")
        
        // Generate a random offset
        let randomOffset = Int.random(in: 0..<totalCount)
        print("🟡 getRandomQuote: Using random offset: \(randomOffset)")
        
        // Get a quote with the random offset
        let response: [DailyQuote] = try await supabase
            .from("quotes")
            .select("""
                *,
                authors!inner(*),
                categories!inner(*)
            """)
            .range(from: randomOffset, to: randomOffset)
            .execute()
            .value
        
        print("🟡 getRandomQuote: Received \(response.count) quotes from Supabase")
        
        guard let randomQuote = response.first else {
            print("🔴 getRandomQuote: No quotes found in response!")
            throw QuoteServiceError.noQuotesFound
        }
        
        print("🟡 getRandomQuote: Successfully got quote: \"\(randomQuote.quoteText.prefix(50))...\"")
        return randomQuote
    }
}

// MARK: - Widget Entry
struct QuotedWidgetEntry: TimelineEntry {
    let date: Date
    let dailyQuote: DailyQuote
}

// MARK: - Widget Views
struct QuotedWidgetSmallView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        VStack(spacing: WidgetStyles.Layout.Spacing.medium) {
            // Next button
            HStack {
                Spacer()
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
            }
            
            // Quote icon
            Image(systemName: WidgetStyles.IconNames.quote)
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
                    
                    Spacer()
                    
                    Image(systemName: WidgetStyles.IconNames.quote)
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
                    
                    Text(entry.dailyQuote.authors.profession)
                        .font(WidgetStyles.Typography.Medium.professionFont)
                        .foregroundColor(WidgetStyles.Colors.tertiaryText)
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
                    Text(WidgetStyles.Labels.dailyQuoteHeader)
                        .font(WidgetStyles.Typography.Large.headerFont)
                        .fontWeight(WidgetStyles.Typography.Large.headerFontWeight)
                        .foregroundColor(WidgetStyles.Colors.secondaryText)
                    
                    Text(WidgetStyles.formatDate(entry.date))
                        .font(WidgetStyles.Typography.Large.dateFont)
                        .foregroundColor(WidgetStyles.Colors.quaternaryText)
                }
                
                Spacer()
                
                // Next button
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
            }
            
            Spacer()
            
            // Quote content
            VStack(spacing: WidgetStyles.Layout.Spacing.extraLarge) {
                // Quote mark
                Image(systemName: WidgetStyles.IconNames.quote)
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
                
                Text(entry.dailyQuote.authors.profession)
                    .font(WidgetStyles.Typography.Large.professionFont)
                    .foregroundColor(WidgetStyles.Colors.secondaryText)
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
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
            )
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
