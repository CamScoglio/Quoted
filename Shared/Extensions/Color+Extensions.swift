//
//  Color+Extensions.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI
import UIKit

extension Color {
    // MARK: - Hex Color Support
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
    
    // MARK: - Theme Colors
    static let quotedPrimary = Color.blue
    static let quotedSecondary = Color.purple
    static let quotedAccent = Color.orange
    
    // MARK: - Gradient Helpers
    static func gradientColors(from startHex: String, to endHex: String) -> [Color] {
        return [Color(hex: startHex), Color(hex: endHex)]
    }
} 