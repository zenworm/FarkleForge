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
    @State private var showingCelebration = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Farkle Forge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
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
                .onChange(of: gameState.winner) { oldValue, newValue in
                    if newValue != nil {
                        showingCelebration = true
                    }
                }
                .fullScreenCover(isPresented: $showingCelebration) {
                    celebrationOverlay
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            if gameState.players.isEmpty {
                emptyStateView
            } else {
                gameInProgressView
            }
        }
    }
    
    private var emptyStateView: some View {
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
                    .cornerRadius(4)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameInProgressView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gameState.players) { player in
                            PlayerRowView(
                                player: player,
                                isCurrentTurn: player.id == gameState.currentPlayer?.id,
                                isFinalRound: gameState.isFinalRound,
                                leaderScore: gameState.leaderScore
                            )
                            .id(player.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: gameState.currentTurnIndex) { oldValue, newValue in
                    if let currentPlayer = gameState.currentPlayer {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(currentPlayer.id, anchor: .center)
                        }
                    }
                }
                .onAppear {
                    if let currentPlayer = gameState.currentPlayer {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(currentPlayer.id, anchor: .center)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            ScoreInputView(currentInput: $currentInput) { score in
                if let currentPlayer = gameState.currentPlayer {
                    gameState.addScore(score, to: currentPlayer.id)
                    gameState.advanceTurn()
                }
            } onFarkle: {
                gameState.advanceTurn()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            if let winner = gameState.winner {
                CelebrationView(winnerName: winner.name) {
                    showingCelebration = false
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}

