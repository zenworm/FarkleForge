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
    @State private var showingGameSetup = false
    @State private var showingResetAlert = false
    @State private var showingCelebration = false
    
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
                // .background(
                //     ZStack {
                //         Image("BackgroundImage")
                //             .resizable()
                //             .scaledToFill()
                //             .ignoresSafeArea(edges: .top)
                        
                //         // Color overlay to tint the background
                //         Color(red: 40/255.0, green: 59/255.0, blue: 36/255.0)
                //             .opacity(0.95)
                //             .ignoresSafeArea(edges: .top)
                //     }
                // )
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
                // Button(action: { showingPlayerList = true }) {
                //     Label("Edit players", systemImage: "person.3.fill")
                // }
                
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

