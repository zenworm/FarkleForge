import SwiftUI

struct PlayerRowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let player: Player
    let isCurrentTurn: Bool
    let isFinalRound: Bool
    let leaderScore: Int
    let targetScore: Int
    let isFirst: Bool
    let isLast: Bool
    var seat: Int = 0

    private var color: Color { Arcade.playerColors[seat % Arcade.playerColors.count] }
    private var progress: Double { min(max(Double(player.score) / Double(max(targetScore, 1)), 0), 1) }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ArcadeDie(face: seat % 6 + 1, size: 31, color: color)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(player.name).font(.system(.body, design: .rounded, weight: .bold)).lineLimit(1)
                        if player.score == leaderScore && player.score > 0 {
                            Image(systemName: "crown.fill").font(.caption).foregroundStyle(Arcade.gold)
                        }
                    }
                    if isCurrentTurn {
                        Text(isFinalRound && player.score < leaderScore ? "\((leaderScore - player.score + 1).formatted()) to take the lead" : "Your dice. Your destiny.")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(Arcade.mint)
                    }
                }
                Spacer(minLength: 4)
                Text(player.score.formatted()).font(Arcade.mono(23))
                    .contentTransition(.numericText(value: Double(player.score)))
                    .foregroundStyle(isCurrentTurn ? Arcade.mint : Arcade.cream)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            GeometryReader { geometry in
                Capsule().fill(.white.opacity(0.07))
                Capsule().fill(color)
                    .frame(width: max(0, geometry.size.width * progress))
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(isCurrentTurn ? Arcade.panel : Arcade.forest.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(isCurrentTurn ? Arcade.mint.opacity(0.65) : .white.opacity(0.06), lineWidth: 1))
        .foregroundStyle(Arcade.cream)
        .overlay(alignment: .trailing) { ScoreSparkles(trigger: player.score, color: color) }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8), value: player.score)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name), \(player.score) points\(isCurrentTurn ? ", current turn" : "")\(player.score == leaderScore && player.score > 0 ? ", leading" : "")")
    }
}
