//
//  PlayerListView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct PlayerListView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @State private var newPlayerName = ""
    @State private var showingAddPlayer = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(gameState.players) { player in
                        HStack {
                            Text(player.name)
                                .font(.headline)
                            Spacer()
                            Text("\(player.score) pts")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deletePlayer)
                }
                
                Section {
                    Button(action: { showingAddPlayer = true }) {
                        Label("Add Player", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Manage Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Add Player", isPresented: $showingAddPlayer) {
                TextField("Player Name", text: $newPlayerName)
                    .focused($isTextFieldFocused)
                Button("Cancel", role: .cancel) {
                    newPlayerName = ""
                }
                Button("Add") {
                    addPlayer()
                }
                .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Enter the player's name")
            }
            .onChange(of: showingAddPlayer) { oldValue, newValue in
                if newValue {
                    // Defer focus to avoid blocking initial view rendering
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                } else {
                    newPlayerName = ""
                    isTextFieldFocused = false
                }
            }
        }
    }
    
    private func addPlayer() {
        let trimmedName = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        gameState.addPlayer(name: trimmedName)
        newPlayerName = ""
    }
    
    private func deletePlayer(at offsets: IndexSet) {
        gameState.removePlayer(at: offsets)
    }
}

#Preview {
    PlayerListView()
        .environment(GameState())
}

