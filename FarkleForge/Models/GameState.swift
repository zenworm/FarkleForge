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
    private struct UndoSnapshot {
        let players: [Player]
        let currentTurnIndex: Int
        let isFinalRound: Bool
        let finalRoundTriggerPlayerId: UUID?
        let finalRoundStartedAtTurnIndex: Int?
        let hasAdvancedSinceFinalRound: Bool
        let winner: Player?
    }
    
    var players: [Player] = []
    var targetScore: Int = 10000 // Default target score
    var currentTurnIndex: Int = 0
    var isFinalRound: Bool = false
    var finalRoundTriggerPlayerId: UUID? = nil
    var finalRoundStartedAtTurnIndex: Int? = nil
    var hasAdvancedSinceFinalRound: Bool = false
    var winner: Player? = nil
    
    private var undoStack: [UndoSnapshot] = []
    
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
    
    var canUndoLastScoreEntry: Bool {
        !undoStack.isEmpty
    }
    
    private func pushUndoSnapshot() {
        undoStack.append(
            UndoSnapshot(
                players: players,
                currentTurnIndex: currentTurnIndex,
                isFinalRound: isFinalRound,
                finalRoundTriggerPlayerId: finalRoundTriggerPlayerId,
                finalRoundStartedAtTurnIndex: finalRoundStartedAtTurnIndex,
                hasAdvancedSinceFinalRound: hasAdvancedSinceFinalRound,
                winner: winner
            )
        )
    }
    
    private func clearUndoHistory() {
        undoStack.removeAll()
    }
    
    func undoLastScoreEntry() {
        guard let snapshot = undoStack.popLast() else { return }
        
        players = snapshot.players
        currentTurnIndex = snapshot.currentTurnIndex
        isFinalRound = snapshot.isFinalRound
        finalRoundTriggerPlayerId = snapshot.finalRoundTriggerPlayerId
        finalRoundStartedAtTurnIndex = snapshot.finalRoundStartedAtTurnIndex
        hasAdvancedSinceFinalRound = snapshot.hasAdvancedSinceFinalRound
        winner = snapshot.winner
        
        invalidateLeaderCache()
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
        clearUndoHistory()
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
        clearUndoHistory()
    }
    
    /// Applies a banked score entry (score + advance turn) and captures an undo snapshot.
    func applyBankedScore(_ points: Int, to playerId: UUID) {
        pushUndoSnapshot()
        addScore(points, to: playerId)
        advanceTurn()
    }
    
    func addScore(_ points: Int, to playerId: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else { return }
        
        let oldScore = players[index].score
        players[index].score += points
        let newScore = players[index].score
        
        // Check if someone just hit target score (entering final round)
        if !isFinalRound && oldScore < targetScore && newScore >= targetScore {
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
        // 1. If someone beats the leader's score during their turn (and has >= target score), 
        //    they win immediately (but only if we've completed at least one full cycle)
        if !hasCompletedCycle,
           currentPlayer.score > currentLeader.score && currentPlayer.score >= targetScore {
            // Someone beat the leader - they win immediately
            winner = currentPlayer
            return
        }
        
        // 2. If we've completed a full cycle, the current leader wins
        if hasCompletedCycle && currentLeader.score >= targetScore {
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
        players.removeAll()
        targetScore = 10000 // Reset to default
        currentTurnIndex = 0
        isFinalRound = false
        finalRoundTriggerPlayerId = nil
        finalRoundStartedAtTurnIndex = nil
        hasAdvancedSinceFinalRound = false
        winner = nil
        invalidateLeaderCache()
        clearUndoHistory()
        PlayerPersistence.save(players)
    }
}

