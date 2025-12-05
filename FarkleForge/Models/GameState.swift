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
    var isFinalRound: Bool = false
    var finalRoundTriggerPlayerId: UUID? = nil
    var finalRoundStartedAtTurnIndex: Int? = nil
    var hasAdvancedSinceFinalRound: Bool = false
    var winner: Player? = nil
    
    // Cache for leader to avoid recalculating on every access
    private var _cachedLeader: Player? = nil
    private var _leaderCacheValid: Bool = false
    
    var currentPlayer: Player? {
        guard !players.isEmpty, currentTurnIndex < players.count else {
            return nil
        }
        return players[currentTurnIndex]
    }
    
    var leader: Player? {
        if !_leaderCacheValid || _cachedLeader == nil {
            _cachedLeader = players.max(by: { $0.score < $1.score })
            _leaderCacheValid = true
        }
        return _cachedLeader
    }
    
    var leaderScore: Int {
        leader?.score ?? 0
    }
    
    private func invalidateLeaderCache() {
        _leaderCacheValid = false
        _cachedLeader = nil
    }
    
    init() {
        // Load saved players on initialization
        self.players = PlayerPersistence.load()
    }
    
    func addPlayer(name: String) {
        let newPlayer = Player(name: name)
        players.append(newPlayer)
        invalidateLeaderCache()
        PlayerPersistence.save(players)
    }
    
    func removePlayer(at offsets: IndexSet) {
        // Adjust current turn if needed
        if let index = offsets.first, index < currentTurnIndex {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        } else if let index = offsets.first, index == currentTurnIndex {
            currentTurnIndex = 0
        }
        
        players.remove(atOffsets: offsets)
        invalidateLeaderCache()
        
        // Reset turn index if no players left
        if players.isEmpty {
            currentTurnIndex = 0
        } else if currentTurnIndex >= players.count {
            currentTurnIndex = 0
        }
        
        PlayerPersistence.save(players)
    }
    
    func addScore(_ points: Int, to playerId: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else { return }
        
        let oldScore = players[index].score
        players[index].score += points
        let newScore = players[index].score
        
        // Check if someone just hit 10,000 (entering final round)
        if !isFinalRound && oldScore < 10000 && newScore >= 10000 {
            isFinalRound = true
            finalRoundTriggerPlayerId = playerId
            finalRoundStartedAtTurnIndex = currentTurnIndex
            hasAdvancedSinceFinalRound = false
        }
        
        // Invalidate leader cache since score changed
        invalidateLeaderCache()
        
        // Check for winner (but only if we've advanced at least once since final round started)
        // This ensures everyone gets a chance to beat the score
        if isFinalRound && hasAdvancedSinceFinalRound {
            checkForWinner()
        }
    }
    
    private func checkForWinner() {
        guard isFinalRound,
              let triggerId = finalRoundTriggerPlayerId,
              let startIndex = finalRoundStartedAtTurnIndex,
              let currentPlayer = currentPlayer else { return }
        
        // Find the current leader (highest score)
        guard let currentLeader = leader else { return }
        
        // Check if we've completed a full cycle (back to the trigger player)
        let hasCompletedCycle = currentPlayer.id == triggerId && currentTurnIndex == startIndex
        
        // During final round:
        // 1. If someone beats the leader's score during their turn (and has >= 10,000), 
        //    they win immediately (but only if we've completed at least one full cycle)
        if !hasCompletedCycle,
           currentPlayer.score > currentLeader.score && currentPlayer.score >= 10000 {
            // Someone beat the leader - they win immediately
            winner = currentPlayer
            return
        }
        
        // 2. If we've completed a full cycle, the current leader wins
        if hasCompletedCycle && currentLeader.score >= 10000 {
            winner = currentLeader
        }
    }
    
    func advanceTurn() {
        guard !players.isEmpty else { return }
        
        // Mark that we've advanced since final round started
        if isFinalRound {
            hasAdvancedSinceFinalRound = true
        }
        
        currentTurnIndex = (currentTurnIndex + 1) % players.count
        
        // Check for winner after advancing turn (in case we've completed the final round)
        if isFinalRound {
            checkForWinner()
        }
    }
    
    func resetGame() {
        for index in players.indices {
            players[index].score = 0
        }
        currentTurnIndex = 0
        isFinalRound = false
        finalRoundTriggerPlayerId = nil
        finalRoundStartedAtTurnIndex = nil
        hasAdvancedSinceFinalRound = false
        winner = nil
        invalidateLeaderCache()
    }
}

