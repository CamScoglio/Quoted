//
//  Author.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

struct Author: Codable, Identifiable {
    let id: UUID
    let name: String
    let profession: String
    let bio: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, profession, bio
        case imageUrl = "image_url"
    }
} 