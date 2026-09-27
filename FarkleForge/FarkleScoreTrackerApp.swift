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

    init() {
        // Render the sound palette up front so the very first tap is instant.
        SoundEngine.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(\.videoCache, videoCache)
        }
    }
}

