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

  var body: some View {
    Group {
      if isAuthenticated {
        ContentView()
      } else {
        StartingView()
      }
    }
    .task {
      for await state in SupabaseManager.shared.client.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          let wasAuthenticated = isAuthenticated
          isAuthenticated = state.session != nil
          
          // Reload widget when authentication state changes
          if wasAuthenticated != isAuthenticated {
            print("🔄 [AppView] Auth state changed - reloading widgets (authenticated: \(isAuthenticated))")
            WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
          }
        }
      }
    }
  }
}
