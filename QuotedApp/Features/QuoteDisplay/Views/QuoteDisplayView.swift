//
//  QuoteDisplayView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

struct QuoteDisplayView: View {
    let quote: DailyQuote
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: responsiveSpacing(for: geometry.size)) {
                // Quote text
                Text(quote.quoteText)
                    .font(responsiveQuoteFont(for: geometry.size))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.adaptiveOverlayText)
                    .multilineTextAlignment(.center)
                    .padding(responsivePadding(for: geometry.size))
                    .lineSpacing(4)
                
                // Author
                Text("— \(quote.authors.name)")
                    .font(responsiveAuthorFont(for: geometry.size))
                    .foregroundColor(AppColors.adaptiveOverlayTextSecondary)
                
                // Category
                if !quote.categories.name.isEmpty {
                    Text(quote.categories.name.uppercased())
                        .font(responsiveCategoryFont(for: geometry.size))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.adaptiveOverlayTextSecondary)
                        .padding(.horizontal, responsiveCategoryPadding(for: geometry.size))
                        .padding(.vertical, responsiveCategoryPadding(for: geometry.size) * 0.5)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(responsiveCornerRadius(for: geometry.size))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Responsive Helpers
    
    private func responsiveSpacing(for size: CGSize) -> CGFloat {
        let baseSpacing: CGFloat = 20
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(baseSpacing * scaleFactor, 15)
    }
    
    private func responsivePadding(for size: CGSize) -> CGFloat {
        let basePadding: CGFloat = 16
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(basePadding * scaleFactor, 12)
    }
    
    private func responsiveQuoteFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 390, size.height / 844)
        
        #if targetEnvironment(macCatalyst)
        // Larger fonts on Mac for better readability
        if scaleFactor > 1.5 {
            return .title.weight(.medium)
        } else if scaleFactor > 1.2 {
            return .title2.weight(.medium)
        }
        #endif
        
        return .title2.weight(.medium)
    }
    
    private func responsiveAuthorFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 390, size.height / 844)
        
        #if targetEnvironment(macCatalyst)
        if scaleFactor > 1.5 {
            return .title3
        } else if scaleFactor > 1.2 {
            return .headline
        }
        #endif
        
        return .headline
    }
    
    private func responsiveCategoryFont(for size: CGSize) -> Font {
        let scaleFactor = min(size.width / 390, size.height / 844)
        
        #if targetEnvironment(macCatalyst)
        if scaleFactor > 1.5 {
            return .subheadline
        } else if scaleFactor > 1.2 {
            return .caption
        }
        #endif
        
        return .caption
    }
    
    private func responsiveCategoryPadding(for size: CGSize) -> CGFloat {
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(12 * scaleFactor, 8)
    }
    
    private func responsiveCornerRadius(for size: CGSize) -> CGFloat {
        let scaleFactor = min(size.width / 390, size.height / 844)
        return max(8 * scaleFactor, 6)
    }
}

