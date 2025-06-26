//
//  SupabaseClient.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//
import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let urlString = config["https://dsrznnimciulnsnrqxoq.supabase.co"] as? String,
              let key = config["eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzcnpubmltY2l1bG5zbnJxeG9xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2MzYyNDUsImV4cCI6MjA2NjIxMjI0NX0.IN2PXEz2ZSqw2DO753-2PLwy_Jf9Q5BcgY067xpiwDg"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Could not load Supabase configuration")
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
