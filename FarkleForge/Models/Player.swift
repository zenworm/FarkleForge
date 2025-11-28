//
//  Player.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import Foundation

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var score: Int
    
    init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}

