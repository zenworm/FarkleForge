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
        .overlay {
            ProgressBuildEmitter(progress: progress, isActive: isCurrentTurn)
                .allowsHitTesting(false)
        }
    }
}

/// Emits tiny "building block" particles from the tip of the progress bar
/// while it animates to a new score.
private struct ProgressBuildEmitter: View {
    let progress: Double
    let isActive: Bool

    @State private var system = BuildParticleSystem()
    @State private var isRunning = false
    @State private var runGeneration = 0

    // Extra canvas space so particles can fly outside the row bounds
    private let margin: CGFloat = 24

    var body: some View {
        TimelineView(.animation(paused: !isRunning)) { timeline in
            Canvas { context, size in
                system.update(at: timeline.date, canvasSize: size, margin: margin)
                for particle in system.particles {
                    let alpha = max(0, 1 - particle.age / particle.lifetime)
                    let rect = CGRect(x: particle.x, y: particle.y, width: particle.size, height: particle.size)
                    context.fill(Path(rect), with: .color(particle.color.opacity(alpha)))
                }
            }
        }
        .padding(-margin)
        .onChange(of: progress) { oldValue, newValue in
            guard isActive, newValue > oldValue else { return }
            system.beginSweep(from: oldValue, to: newValue)
            isRunning = true
            runGeneration += 1
            let generation = runGeneration
            // Stop the render loop once the sweep and the longest-lived particles are done
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if generation == runGeneration {
                    isRunning = false
                }
            }
        }
    }
}

private final class BuildParticleSystem {
    struct Particle {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var age: TimeInterval
        let lifetime: TimeInterval
        let size: CGFloat
        let color: Color
    }

    private(set) var particles: [Particle] = []
    private var sweepStart: Double = 0
    private var sweepEnd: Double = 0
    private var sweepBeganAt: Date?
    private var lastUpdate: Date?

    // Matches the progress bar's .easeOut(duration: 0.6) animation
    private let sweepDuration: TimeInterval = 0.6
    private let gravity: CGFloat = 260

    private static let palette: [Color] = [
        Color(red: 185/255.0, green: 239/255.0, blue: 168/255.0), // #B9EFA8
        Color(red: 96/255.0, green: 191/255.0, blue: 72/255.0),   // #60BF48
        Color(red: 233/255.0, green: 255/255.0, blue: 224/255.0), // #E9FFE0
    ]

    func beginSweep(from: Double, to: Double) {
        sweepStart = from
        sweepEnd = to
        sweepBeganAt = Date()
    }

    func update(at date: Date, canvasSize: CGSize, margin: CGFloat) {
        let dt = min(lastUpdate.map { date.timeIntervalSince($0) } ?? 0, 1.0 / 20.0)
        lastUpdate = date

        for index in particles.indices {
            particles[index].age += dt
            particles[index].vy += gravity * dt
            particles[index].x += particles[index].vx * dt
            particles[index].y += particles[index].vy * dt
        }
        particles.removeAll { $0.age >= $0.lifetime }

        // Emit from the moving tip while the sweep plays
        guard let beganAt = sweepBeganAt else { return }
        let t = date.timeIntervalSince(beganAt) / sweepDuration
        if t >= 1 {
            sweepBeganAt = nil
            return
        }
        let eased = 1 - pow(1 - t, 3) // ease-out, rides alongside the bar's tip
        let rowWidth = canvasSize.width - margin * 2
        let rowHeight = canvasSize.height - margin * 2
        let tipX = margin + rowWidth * (sweepStart + (sweepEnd - sweepStart) * eased)

        for _ in 0..<3 {
            particles.append(
                Particle(
                    x: tipX + .random(in: -2...4),
                    y: margin + .random(in: 0...rowHeight),
                    vx: .random(in: -30...60),
                    vy: .random(in: -110 ... -20),
                    age: 0,
                    lifetime: .random(in: 0.35...0.8),
                    size: [2, 3, 3, 4].randomElement()!,
                    color: Self.palette.randomElement()!
                )
            )
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        PlayerRowView(player: Player(name: "Alice", score: 10000), isCurrentTurn: true, isFinalRound: true, leaderScore: 10000, targetScore: 10000, isFirst: true, isLast: false)
        PlayerRowView(player: Player(name: "Bob", score: 8500), isCurrentTurn: false, isFinalRound: true, leaderScore: 10000, targetScore: 10000, isFirst: false, isLast: true)
    }
    .padding()
}

