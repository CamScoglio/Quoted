//
//  QuotedApp.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import SwiftUI

@main
struct QuotedApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userManager.isLoading {
                    LoadingView()
                } else if userManager.isAuthenticated {
                    ContentView()
                        .environmentObject(userManager)
                        .environmentObject(analyticsManager)
                } else {
                    WelcomeView()
                        .environmentObject(userManager)
                        .environmentObject(analyticsManager)
                }
            }
            .task {
                // Track app opening
                await analyticsManager.trackAppOpened()
            }
        }
    }
} 