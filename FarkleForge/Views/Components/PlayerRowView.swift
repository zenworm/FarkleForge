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
    
    var progress: Double {
        min(Double(player.score) / 10000.0, 1.0)
    }
    
    var progressBarColor: Color {
        if isCurrentTurn {
            return Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0).opacity(0.3) // #ffffff at 30%
        } else {
            return Color(red: 159/255.0, green: 255/255.0, blue: 161/255.0).opacity(0.12) // #9FFFA1 at 12%
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background container
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrentTurn ? Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) : Color.clear) // #60C946 or transparent
            
            // Progress bar (full bleed on left, top, bottom)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressBarColor)
                    .frame(width: geometry.size.width * progress)
                    .frame(maxHeight: .infinity, alignment: .leading)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentTurn ? Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0))
                    
                    Spacer()
                    
                    Text("\(player.score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(isCurrentTurn ? Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0))
                }
                
                if let pointsNeeded = pointsNeeded, isCurrentTurn {
                    Text("Need \(pointsNeeded) points to win")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isCurrentTurn ? Color(red: 188/255.0, green: 249/255.0, blue: 172/255.0).opacity(0.5) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0).opacity(0.3), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack {
        PlayerRowView(player: Player(name: "Alice", score: 10000), isCurrentTurn: true, isFinalRound: true, leaderScore: 10000)
        PlayerRowView(player: Player(name: "Bob", score: 8500), isCurrentTurn: false, isFinalRound: true, leaderScore: 10000)
    }
    .padding()
}

