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

// MARK: - Widget Timeline Provider
struct QuotedWidgetProvider: TimelineProvider {
    private let quoteService = QuoteService()
    
    func placeholder(in context: Context) -> QuotedWidgetEntry {
        QuotedWidgetEntry(
            date: Date(),
            dailyQuote: DailyQuote(
                quote: Quote(
                    id: UUID(),
                    quoteText: "The only way to do great work is to love what you do.",
                    authorId: UUID(),
                    categoryId: UUID(),
                    designTheme: "minimal",
                    backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                    isFeatured: true,
                    createdAt: Date()
                ),
                author: Author(
                    id: UUID(),
                    name: "Steve Jobs",
                    profession: "Entrepreneur",
                    bio: nil,
                    imageUrl: nil
                ),
                category: Category(id: UUID(), name: "Motivation", color: "#667eea")
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuotedWidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuotedWidgetEntry>) -> Void) {
        Task {
            do {
                let dailyQuote: DailyQuote
                
                if context.isPreview {
                    // Use placeholder for preview
                    dailyQuote = placeholder(in: context).dailyQuote
                } else {
                    // Get a random quote for each refresh (including Next button taps)
                    dailyQuote = try await quoteService.getRandomQuote()
                }
                
                let entry = QuotedWidgetEntry(date: Date(), dailyQuote: dailyQuote)
                
                // Set next refresh for 24 hours from now to maintain daily update cycle
                let nextRefresh = Date().addingTimeInterval(24 * 60 * 60)
                
                // Use .atEnd policy to allow manual refreshes via the Next button
                let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
                completion(timeline)
                
            } catch {
                // Fallback to placeholder on error
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))) // Retry in 1 hour
                completion(timeline)
            }
        }
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
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack(spacing: 8) {
                // Next button
                HStack {
                    Spacer()
                    Button(intent: NextQuoteIntent()) {
                        HStack(spacing: 4) {
                            Text("Next")
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                        )
                    }
                }
                
                // Quote icon
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                // Truncated quote text
                Text(truncatedQuote)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Spacer()
                
                // Author name
                Text("— \(entry.dailyQuote.author.name)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var truncatedQuote: String {
        let text = entry.dailyQuote.quote.quoteText
        return text.count > 100 ? String(text.prefix(97)) + "..." : text
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientColors: [Color] {
        guard let gradient = entry.dailyQuote.quote.backgroundGradient,
              let startHex = gradient["start"],
              let endHex = gradient["end"] else {
            return [Color.blue, Color.purple]
        }
        
        return [Color(hex: startHex), Color(hex: endHex)]
    }
}

struct QuotedWidgetMediumView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    // Next button
                    HStack {
                        Button(intent: NextQuoteIntent()) {
                            HStack(spacing: 4) {
                                Text("Next")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.2))
                            )
                        }
                        
                        Spacer()
                        
                        Image(systemName: "quote.bubble.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Quote text
                    Text(entry.dailyQuote.quote.quoteText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Author info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("— \(entry.dailyQuote.author.name)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(entry.dailyQuote.author.profession)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientColors: [Color] {
        guard let gradient = entry.dailyQuote.quote.backgroundGradient,
              let startHex = gradient["start"],
              let endHex = gradient["end"] else {
            return [Color.blue, Color.purple]
        }
        
        return [Color(hex: startHex), Color(hex: endHex)]
    }
}

struct QuotedWidgetLargeView: View {
    let entry: QuotedWidgetEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAILY QUOTE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(formattedDate)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Next button
                    Button(intent: NextQuoteIntent()) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white.opacity(0.2))
                        )
                    }
                }
                
                Spacer()
                
                // Quote content
                VStack(spacing: 16) {
                    // Quote mark
                    Image(systemName: "quote.bubble.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Quote text
                    Text(entry.dailyQuote.quote.quoteText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                // Author section
                VStack(spacing: 8) {
                    Text("— \(entry.dailyQuote.author.name)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(entry.dailyQuote.author.profession)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: entry.date)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientColors: [Color] {
        guard let gradient = entry.dailyQuote.quote.backgroundGradient,
              let startHex = gradient["start"],
              let endHex = gradient["end"] else {
            return [Color.blue, Color.purple]
        }
        
        return [Color(hex: startHex), Color(hex: endHex)]
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
                .containerBackground(for: .widget) {
                    Color.clear
                }
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
                quote: Quote(
                    id: UUID(),
                    quoteText: "The only way to do great work is to love what you do.",
                    authorId: UUID(),
                    categoryId: UUID(),
                    designTheme: "minimal",
                    backgroundGradient: ["start": "#667eea", "end": "#764ba2"],
                    isFeatured: true,
                    createdAt: Date()
                ),
                author: Author(
                    id: UUID(),
                    name: "Steve Jobs",
                    profession: "Entrepreneur",
                    bio: nil,
                    imageUrl: nil
                ),
                category: Category(id: UUID(), name: "Motivation", color: "#667eea")
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
