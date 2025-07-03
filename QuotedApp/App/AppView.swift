//
//  AppView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/22/25.
//
///Changes chagnes changes changes
import Foundation
import SwiftUI
import WidgetKit

struct AppView: View {
  @State var isAuthenticated = false
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

  var body: some View {
    Group {
      // Three-state navigation system
      if !isAuthenticated && !hasCompletedOnboarding {
        // Not authenticated, not onboarded → Start onboarding
        StartingView()
      } else if isAuthenticated && !hasCompletedOnboarding {
        // Authenticated but not onboarded → Show success screen
        OffboardingView()
      } else if isAuthenticated && hasCompletedOnboarding {
        // Authenticated and onboarded → Main app
        ContentView()
      } else {
        // Fallback: Not authenticated but somehow onboarded → Reset and start over
        StartingView()
          .onAppear {
            print("🔄 [AppView] Inconsistent state detected - resetting onboarding flag")
            hasCompletedOnboarding = false
          }
      }
    }
    .task {
      for await state in SupabaseService.shared.client.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          await MainActor.run {
            let wasAuthenticated = isAuthenticated
            isAuthenticated = state.session != nil
            
            // Reset onboarding flag when user signs out
            if wasAuthenticated && !isAuthenticated {
              print("🔄 [AppView] User signed out → clearing widget timelines and resetting onboarding")
              hasCompletedOnboarding = false
              WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            }
            
            print("🔄 [AppView] Navigation state: authenticated=\(isAuthenticated), onboarded=\(hasCompletedOnboarding)")
            
            // Print current navigation decision
            if !isAuthenticated && !hasCompletedOnboarding {
              print("🔄 [AppView] → Showing StartingView (need auth + onboarding)")
            } else if isAuthenticated && !hasCompletedOnboarding {
              print("🔄 [AppView] → Showing OffboardingView (auth ✅, onboarding pending)")
            } else if isAuthenticated && hasCompletedOnboarding {
              print("🔄 [AppView] → Showing ContentView (auth ✅, onboarding ✅)")
            }
          }
        }
      }
    }
  }
}
  
