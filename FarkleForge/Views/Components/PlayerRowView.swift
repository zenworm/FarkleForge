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
    let targetScore: Int
    let isFirst: Bool
    let isLast: Bool
    
    init(player: Player, isCurrentTurn: Bool, isFinalRound: Bool, leaderScore: Int, targetScore: Int, isFirst: Bool, isLast: Bool) {
        self.player = player
        self.isCurrentTurn = isCurrentTurn
        self.isFinalRound = isFinalRound
        self.leaderScore = leaderScore
        self.targetScore = targetScore
        self.isFirst = isFirst
        self.isLast = isLast
    }
    
    var pointsNeeded: Int? {
        guard isFinalRound, player.score < leaderScore else { return nil }
        return leaderScore - player.score + 1
    }
    
    var progress: Double {
        min(Double(player.score) / Double(targetScore), 1.0)
    }
    
    var progressBarColor: Color {
        if isCurrentTurn {
            return Color(red: 33/255.0, green: 204/255.0, blue: 38/255.0) // #21CC26
        } else {
            return Color(red: 159/255.0, green: 255/255.0, blue: 161/255.0).opacity(0.12) // #9FFFA1 at 12%
        }
    }
    
    private var cornerRadius: CGFloat = 4
    
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? cornerRadius : 0,
            bottomLeadingRadius: isLast ? cornerRadius : 0,
            bottomTrailingRadius: isLast ? cornerRadius : 0,
            topTrailingRadius: isFirst ? cornerRadius : 0
        )
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background container
            shape
                .fill(isCurrentTurn ? Color(red: 120/255.0, green: 220/255.0, blue: 115/255.0) : Color.clear) // #78DC73 or transparent
            
            // Progress bar (full bleed on left, top, bottom)
            GeometryReader { geometry in
                shape
                    .fill(progressBarColor)
                    .frame(width: geometry.size.width * progress)
                    .frame(maxHeight: .infinity, alignment: .leading)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(player.name)
                        .font(.custom("Daydream", size: 20))
                        .foregroundColor(isCurrentTurn ? Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0))
                    
                    Spacer()
                    
                    Text("\(player.score)")
                        .font(.custom("Daydream", size: 20))
                        .foregroundColor(isCurrentTurn ? Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0))
                }
                
                if let pointsNeeded = pointsNeeded, isCurrentTurn {
                    Text("\(pointsNeeded) to win")
                        .font(.custom("Daydream", size: 12))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
        .overlay(
            shape
                .stroke(isCurrentTurn ? Color(red: 188/255.0, green: 249/255.0, blue: 172/255.0).opacity(0.5) : Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0).opacity(0.3), lineWidth: 2)
        )
        .clipShape(shape)
    }
}

#Preview {
    VStack(spacing: 0) {
        PlayerRowView(player: Player(name: "Alice", score: 10000), isCurrentTurn: true, isFinalRound: true, leaderScore: 10000, targetScore: 10000, isFirst: true, isLast: false)
        PlayerRowView(player: Player(name: "Bob", score: 8500), isCurrentTurn: false, isFinalRound: true, leaderScore: 10000, targetScore: 10000, isFirst: false, isLast: true)
    }
    .padding()
}

