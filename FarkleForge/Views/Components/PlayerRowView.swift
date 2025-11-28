//
//  PlayerRowView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct PlayerRowView: View {
    let player: Player
    let isCurrentTurn: Bool
    let isFinalRound: Bool
    let leaderScore: Int
    
    var pointsNeeded: Int? {
        guard isFinalRound, player.score < leaderScore else { return nil }
        return leaderScore - player.score + 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(player.name)
                    .font(.title2)
                    .fontWeight(isCurrentTurn ? .bold : .semibold)
                
                Spacer()
                
                Text("\(player.score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentTurn ? .green : .primary)
            }
            
            if let pointsNeeded = pointsNeeded, isCurrentTurn {
                Text("Need \(pointsNeeded) points to win")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrentTurn ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isCurrentTurn ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VStack {
        PlayerRowView(player: Player(name: "Alice", score: 10000), isCurrentTurn: true, isFinalRound: true, leaderScore: 10000)
        PlayerRowView(player: Player(name: "Bob", score: 8500), isCurrentTurn: false, isFinalRound: true, leaderScore: 10000)
    }
    .padding()
}

