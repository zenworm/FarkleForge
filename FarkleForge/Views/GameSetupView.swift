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
    @State private var playerNames: [String] = []
    
    private let bankColor = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) // #60C946
    private let containerColor = Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) // #1B2918
    private let playerCounts = [2, 3, 4, 5, 6, 7, 8]
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if showingAddPlayers {
                    addPlayersView
                } else {
                    setupView
                }
            }
            .onChange(of: gameState.players.count) { oldValue, newValue in
                // Auto-dismiss when players are added
                if newValue > 0 && oldValue == 0 {
                    dismiss()
                }
            }
        }
    }
    
    private var setupView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 30) {
                // Player count selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Number of Players")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(playerCounts, id: \.self) { count in
                            Button(action: {
                                selectedPlayerCount = count
                            }) {
                                Text("\(count)")
                                    .font(.custom("Daydream", size: 24))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .foregroundColor(selectedPlayerCount == count ? Color.black : Color.gray)
                                    .background(selectedPlayerCount == count ? bankColor : Color.clear)
                                    .cornerRadius(3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(selectedPlayerCount == count ? bankColor : Color.gray, lineWidth: 2)
                                    )
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
                    
                    HStack(spacing: 0) {
                        ForEach(Array([2500, 5000, 10000].enumerated()), id: \.element) { index, score in
                            let isFirst = index == 0
                            let isLast = index == 2
                            let isSelected = gameState.targetScore == score
                            
                            Button(action: {
                                gameState.targetScore = score
                            }) {
                                Text(score == 2500 ? "2,500" : score == 5000 ? "5,000" : "10,000")
                                    .font(.custom("Daydream", size: 18))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .foregroundColor(isSelected ? Color.black : Color.gray)
                                    .background(isSelected ? bankColor : Color.clear)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: isFirst ? 3 : 0,
                                            bottomLeadingRadius: isFirst ? 3 : 0,
                                            bottomTrailingRadius: isLast ? 3 : 0,
                                            topTrailingRadius: isLast ? 3 : 0
                                        )
                                    )
                                    .overlay(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: isFirst ? 3 : 0,
                                            bottomLeadingRadius: isFirst ? 3 : 0,
                                            bottomTrailingRadius: isLast ? 3 : 0,
                                            topTrailingRadius: isLast ? 3 : 0
                                        )
                                        .stroke(isSelected ? bankColor : Color.gray, lineWidth: 2)
                                    )
                            }
                        }
                    } 
                }
                .padding()
                
                Spacer()
                
                // Continue button
                Button(action: {
                    // Initialize array synchronously before animation
                    playerNames = Array(repeating: "", count: selectedPlayerCount)
                    withAnimation {
                        showingAddPlayers = true
                    }
                }) {
                    Text("Let's Farkle!")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(bankColor)
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                            .stroke(bankColor, lineWidth: 2)
                        )
                }
                .disabled(!gameState.players.isEmpty)
                .padding()
            }
            
            Spacer()
        }
    }
    
    private var addPlayersView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<selectedPlayerCount, id: \.self) { index in
                        TextField("Player \(index + 1)", text: Binding(
                            get: { 
                                guard index < playerNames.count else { return "" }
                                return playerNames[index]
                            },
                            set: { newValue in
                                guard index < playerNames.count else { return }
                                playerNames[index] = newValue
                            }
                        ))
                        .font(.custom("Daydream", size: 20))
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .onAppear {
                // Ensure array is always the correct size when view appears
                if playerNames.count != selectedPlayerCount {
                    playerNames = Array(repeating: "", count: selectedPlayerCount)
                }
            }
            
            Button(action: finishSetup) {
                Text("Start Game")
                    .font(.custom("Daydream", size: 20))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(canStartGame ? bankColor : .gray)
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(canStartGame ? bankColor : .gray, lineWidth: 2)
                    )
            }
            .disabled(!canStartGame)
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    withAnimation {
                        showingAddPlayers = false
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
    }
}

#Preview {
    GameSetupView()
        .environment(GameState())
}

