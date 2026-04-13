//
//  ContentView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.videoCache) private var videoCache
    @State private var currentInput = ""
    @State private var showingPlayerList = false
    @State private var showingGameSetup = false
    @State private var showingResetAlert = false
    @State private var showingCelebration = false
    @State private var gameVideoURL: URL? = nil
    @State private var gameImageName: String? = nil
    
    var body: some View {
        Group {
            if gameState.players.isEmpty {
                // Splash screen - no navigation
                SplashView(onStartGame: {
                    showingGameSetup = true
                })
                .sheet(isPresented: $showingGameSetup) {
                    GameSetupView()
                }
            } else {
                // Game view - with navigation
                NavigationStack {
                    gameInProgressView
                        .navigationTitle("What The Farkle")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            toolbarContent
                        }
                        .sheet(isPresented: $showingPlayerList) {
                            PlayerListView()
                        }
                        .alert("Start over", isPresented: $showingResetAlert) {
                            Button("Cancel", role: .cancel) { }
                            Button("Reset", role: .destructive) {
                                gameState.resetGame()
                                currentInput = ""
                            }
                        } message: {
                            Text("This will remove all players and reset the game. Are you sure?")
                        }
                        .onChange(of: gameState.winner) { _, newValue in
                            if newValue != nil {
                                showingCelebration = true
                            }
                        }
                        .fullScreenCover(isPresented: $showingCelebration, onDismiss: {
                            gameState.resetScores()
                        }) {
                            celebrationOverlay
                        }
                }
            }
        }
    }
    
    private var gameInProgressView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                            PlayerRowView(
                                player: player,
                                isCurrentTurn: player.id == gameState.currentPlayer?.id,
                                isFinalRound: gameState.isFinalRound,
                                leaderScore: gameState.leaderScore,
                                targetScore: gameState.targetScore,
                                isFirst: index == 0,
                                isLast: index == gameState.players.count - 1
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
                    gameState.applyBankedScore(score, to: currentPlayer.id)
                    currentInput = ""
                }
            } onFarkle: {
                gameState.advanceTurn()
            }
        }
        .background {
            if let name = gameImageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.15)
            }
        }
        .onAppear {
            if gameImageName == nil {
                let selection = videoCache.selectForNewGame()
                gameVideoURL = selection.url
                gameImageName = selection.name
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("What The Farkle")
                .font(.custom("Daydream", size: 16))
                .fontWeight(.bold)
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            if !gameState.players.isEmpty {
                Button(action: {
                    gameState.undoLastScoreEntry()
                    currentInput = ""
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!gameState.canUndoLastScoreEntry)
                .opacity(gameState.canUndoLastScoreEntry ? 1.0 : 0.35)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if !gameState.players.isEmpty {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        Label("Start over", systemImage: "arrow.counterclockwise")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            if let winner = gameState.winner {
                CelebrationView(winnerName: winner.name, videoURL: gameVideoURL) {
                    let selection = videoCache.selectForNewGame()
                    gameVideoURL = selection.url
                    gameImageName = selection.name
                    showingCelebration = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}

