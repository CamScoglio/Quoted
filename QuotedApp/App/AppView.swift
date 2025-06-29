//
//  AppView.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/22/25.
//
///Changes chagnes changes changes
import Foundation
import SwiftUI

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
      for await state in supabase.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(state.event) {
          isAuthenticated = state.session != nil
        }
      }
    }
  }
}
