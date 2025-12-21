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
        NavigationStack {
            mainContent
                .navigationTitle("What The Farkle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingGameSetup) {
                    GameSetupView()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            
            Button(action: { showingGameSetup = true }) {
                Text("Start game")
                    .font(.custom("Daydream", size: 20))
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
                .background(
                    ZStack {
                        Image("BackgroundImage")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea(edges: .top)
                        
                        // Color overlay to tint the background
                        Color(red: 40/255.0, green: 59/255.0, blue: 36/255.0)
                            .opacity(0.95)
                            .ignoresSafeArea(edges: .top)
                    }
                )
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
                Button(action: { showingPlayerList = true }) {
                    Label("Manage Players", systemImage: "person.3.fill")
                }
                
                if !gameState.players.isEmpty {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        Label("Reset Game", systemImage: "arrow.counterclockwise")
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

