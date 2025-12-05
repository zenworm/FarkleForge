//
//  PlayerPersistence.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import Foundation

struct PlayerPersistence {
    private static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private static let archiveURL = documentsDirectory.appendingPathComponent("players.json")
    
    /// Save players to disk
    static func save(_ players: [Player]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(players)
            try data.write(to: archiveURL)
        } catch {
            print("Failed to save players: \(error.localizedDescription)")
        }
    }
    
    /// Load players from disk
    static func load() -> [Player] {
        do {
            let data = try Data(contentsOf: archiveURL)
            let decoder = JSONDecoder()
            return try decoder.decode([Player].self, from: data)
        } catch {
            // File doesn't exist or couldn't be decoded - return empty array
            return []
        }
    }
    
    /// Clear saved players
    static func clear() {
        do {
            try FileManager.default.removeItem(at: archiveURL)
        } catch {
            print("Failed to clear saved players: \(error.localizedDescription)")
        }
    }
}

