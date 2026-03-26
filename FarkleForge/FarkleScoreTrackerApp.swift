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
    @State private var videoCache = CelebrationVideoCache()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(\.videoCache, videoCache)
        }
    }
}

