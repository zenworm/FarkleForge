//
//  ContentView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @State private var currentInput = ""
    @State private var showingPlayerList = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if gameState.players.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No Players Yet")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Add players to start tracking scores")
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingPlayerList = true }) {
                            Label("Add Players", systemImage: "person.badge.plus")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Game in progress
                    ScrollView {
                        VStack(spacing: 16) {
                            // Current player indicator
                            if let currentPlayer = gameState.currentPlayer {
                                VStack(spacing: 8) {
                                    Text("Current Turn")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(currentPlayer.name)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Player list
                            ForEach(gameState.players) { player in
                                PlayerRowView(
                                    player: player,
                                    isCurrentTurn: player.id == gameState.currentPlayer?.id
                                )
                            }
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // Score input
                    ScoreInputView(currentInput: $currentInput) { score in
                        if let currentPlayer = gameState.currentPlayer {
                            gameState.addScore(score, to: currentPlayer.id)
                            gameState.advanceTurn()
                        }
                    }
                }
            }
            .navigationTitle("Farkle Scorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !gameState.players.isEmpty {
                        Button(action: { showingResetAlert = true }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPlayerList = true }) {
                        Image(systemName: "person.3.fill")
                    }
                }
            }
            .sheet(isPresented: $showingPlayerList) {
                PlayerListView()
            }
            .alert("Reset Game", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    gameState.resetGame()
                    currentInput = ""
                }
            } message: {
                Text("This will reset all scores to 0. Are you sure?")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}

