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
      for await state in SupabaseService.shared.client.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          await MainActor.run {
            let wasAuthenticated = isAuthenticated
            isAuthenticated = state.session != nil
            if wasAuthenticated && !isAuthenticated {
              print("🔄 [AppView] User signed out → clearing widget timelines")
              WidgetCenter.shared.reloadTimelines(ofKind: "QuotedWidget")
            }
          }
        }
      }
    }
  }
}
  
