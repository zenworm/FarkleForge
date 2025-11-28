//
//  FarkleScoreTrackerApp.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

@main
struct FarkleScoreTrackerApp: App {
    @State private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
        }
    }
}

