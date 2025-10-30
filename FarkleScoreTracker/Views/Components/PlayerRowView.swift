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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.title2)
                    .fontWeight(isCurrentTurn ? .bold : .semibold)
                
                if isCurrentTurn {
                    Text("Current Turn")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Text("\(player.score)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(isCurrentTurn ? .green : .primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentTurn ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentTurn ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VStack {
        PlayerRowView(player: Player(name: "Alice", score: 1250), isCurrentTurn: true)
        PlayerRowView(player: Player(name: "Bob", score: 850), isCurrentTurn: false)
    }
    .padding()
}

