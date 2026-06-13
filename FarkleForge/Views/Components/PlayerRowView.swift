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
            return Color(red: 185/255.0, green: 239/255.0, blue: 168/255.0) // #B9EFA8
        } else {
            return Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0).opacity(0.6) // #91DA7F at 60%
        }
    }

    private var nameColor: Color {
        if isCurrentTurn {
            return Color(red: 22/255.0, green: 34/255.0, blue: 19/255.0) // #162213
        } else {
            return Color.white.opacity(0.8) // #FFFFFF at 80%
        }
    }

    private var scoreColor: Color {
        if isCurrentTurn {
            return Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) // #1B2918
        } else {
            return Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0) // #91DA7F
        }
    }
    
    private var cornerRadius: CGFloat = 0
    
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
                .fill(isCurrentTurn ? Color(red: 96/255.0, green: 191/255.0, blue: 72/255.0) : Color.clear) // #60BF48 or transparent
            
            // Progress bar (full bleed on left, top, bottom)
            GeometryReader { geometry in
                shape
                    .fill(progressBarColor)
                    .frame(width: geometry.size.width * progress)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .animation(.easeOut(duration: 0.6), value: progress)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(player.name)
                        .font(.custom("JetBrainsMono-Medium", size: 20))
                        .foregroundColor(nameColor)

                    Spacer()

                    Text("\(player.score)")
                        .font(.custom("GeistMono-Bold", size: 20))
                        .foregroundColor(scoreColor)
                }

                if let pointsNeeded = pointsNeeded, isCurrentTurn {
                    Text("\(pointsNeeded) to win")
                        .font(.custom("JetBrainsMono-Regular", size: 12))
                        .foregroundColor(nameColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
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

