//
//  GameState.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import Foundation
import Observation

@Observable
class GameState {
    var players: [Player] = []
    var currentTurnIndex: Int = 0
    
    var currentPlayer: Player? {
        guard !players.isEmpty, currentTurnIndex < players.count else {
            return nil
        }
        return players[currentTurnIndex]
    }
    
    init() {
        // Start with empty player list
    }
    
    func addPlayer(name: String) {
        let newPlayer = Player(name: name)
        players.append(newPlayer)
    }
    
    func removePlayer(at offsets: IndexSet) {
        // Adjust current turn if needed
        if let index = offsets.first, index < currentTurnIndex {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        } else if let index = offsets.first, index == currentTurnIndex {
            currentTurnIndex = 0
        }
        
        players.remove(atOffsets: offsets)
        
        // Reset turn index if no players left
        if players.isEmpty {
            currentTurnIndex = 0
        } else if currentTurnIndex >= players.count {
            currentTurnIndex = 0
        }
    }
    
    func addScore(_ points: Int, to playerId: UUID) {
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].score += points
        }
    }
    
    func advanceTurn() {
        guard !players.isEmpty else { return }
        currentTurnIndex = (currentTurnIndex + 1) % players.count
    }
    
    func resetGame() {
        for index in players.indices {
            players[index].score = 0
        }
        currentTurnIndex = 0
    }
}

