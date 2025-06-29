//
//  Category.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

struct Category: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String?
    let themeColor: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case themeColor = "theme_color"
        case createdAt = "created_at"
    }
} 