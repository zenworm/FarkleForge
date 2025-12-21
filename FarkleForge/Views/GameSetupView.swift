//
//  GameSetupView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct GameSetupView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerCount: Int = 2
    @State private var showingAddPlayers = false
    
    private let playerCounts = [2, 3, 4, 5, 6, 7, 8]
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Player count selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Number of Players")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(playerCounts, id: \.self) { count in
                            Button(action: {
                                selectedPlayerCount = count
                            }) {
                                Text("\(count)")
                                    .font(.custom("Daydream", size: 24))
                                    .fontWeight(.bold)
                                    .frame(width: 60, height: 60)
                                    .background(selectedPlayerCount == count ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedPlayerCount == count ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                
                // Game length toggle
                VStack(alignment: .leading, spacing: 16) {
                    Text("Game Length")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                    
                    Picker("Target Score", selection: Binding(
                        get: { gameState.targetScore },
                        set: { gameState.targetScore = $0 }
                    )) {
                        Text("2,500").tag(2500)
                        Text("5,000").tag(5000)
                        Text("10,000").tag(10000)
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                Spacer()
                
                // Continue button
                Button(action: {
                    showingAddPlayers = true
                }) {
                    Text("Continue")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!gameState.players.isEmpty)
                .padding()
            }
            .navigationTitle("Setup Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayers) {
                AddPlayersView(playerCount: selectedPlayerCount, onComplete: {
                    dismiss()
                })
            }
            .onChange(of: gameState.players.count) { oldValue, newValue in
                // Auto-dismiss when players are added
                if newValue > 0 && oldValue == 0 {
                    dismiss()
                }
            }
        }
    }
}

struct AddPlayersView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    let playerCount: Int
    let onComplete: () -> Void
    
    @State private var playerNames: [String] = []
    
    init(playerCount: Int, onComplete: @escaping () -> Void = {}) {
        self.playerCount = playerCount
        self.onComplete = onComplete
        _playerNames = State(initialValue: Array(repeating: "", count: playerCount))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<playerCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Player \(index + 1)")
                                    .font(.custom("Daydream", size: 16))
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter player name", text: Binding(
                                    get: { index < playerNames.count ? playerNames[index] : "" },
                                    set: { 
                                        if index < playerNames.count {
                                            playerNames[index] = $0
                                        }
                                    }
                                ))
                                .font(.custom("Daydream", size: 20))
                                .textFieldStyle(.roundedBorder)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                Divider()
                
                Button(action: finishSetup) {
                    Text("Start Game")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canStartGame ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(canStartGame ? .white : .gray)
                        .cornerRadius(8)
                }
                .disabled(!canStartGame)
                .padding()
            }
            .navigationTitle("Add Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canStartGame: Bool {
        playerNames.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    private func finishSetup() {
        // Add all players
        for name in playerNames {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                gameState.addPlayer(name: trimmed)
            }
        }
        dismiss()
        onComplete()
    }
}

#Preview {
    GameSetupView()
        .environment(GameState())
}

