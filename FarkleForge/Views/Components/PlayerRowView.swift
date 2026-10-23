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
    /// The leader wears the crown. It hops between rows via matched geometry.
    let hasCrown: Bool
    let crownNamespace: Namespace.ID?
    /// The cursor points at whose turn it is, hopping between rows the same way.
    let cursorNamespace: Namespace.ID?
    /// The game is decided and this player won: bigger crown, gold glow.
    var isWinner: Bool = false
    /// Reports where the score sits (in the "game" coordinate space) so a banked
    /// number knows where to fly.
    var onScoreFrame: (CGRect) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(player: Player, isCurrentTurn: Bool, isFinalRound: Bool, leaderScore: Int, targetScore: Int, isFirst: Bool, isLast: Bool, hasCrown: Bool = false, crownNamespace: Namespace.ID? = nil, cursorNamespace: Namespace.ID? = nil, isWinner: Bool = false, onScoreFrame: @escaping (CGRect) -> Void = { _ in }) {
        self.player = player
        self.isCurrentTurn = isCurrentTurn
        self.isFinalRound = isFinalRound
        self.leaderScore = leaderScore
        self.targetScore = targetScore
        self.isFirst = isFirst
        self.isLast = isLast
        self.hasCrown = hasCrown
        self.crownNamespace = crownNamespace
        self.cursorNamespace = cursorNamespace
        self.isWinner = isWinner
        self.onScoreFrame = onScoreFrame
    }
    
    var pointsNeeded: Int? {
        guard isFinalRound, !isWinner, player.score < leaderScore else { return nil }
        return leaderScore - player.score + 1
    }
    
    var progress: Double {
        min(Double(player.score) / Double(targetScore), 1.0)
    }
    
    var progressBarColor: Color {
        if isCurrentTurn {
            return Palette.fern // #4BA834
        } else {
            return Palette.fern.opacity(0.6) // #4BA834 at 60%
        }
    }

    /// Every bar ends in a bright edge, except an empty one: a score of 0 has no bar.
    private var showsBarEdge: Bool {
        player.score > 0
    }

    // Light text on every row; the bars and the row fill mark whose turn it is.
    private let nameColor = Color.white.opacity(0.8) // #FFFFFF at 80%
    private let scoreColor = Palette.sprout // #B9EFA8

    /// Background fill for the active player. Tweak the `.opacity(...)` value
    /// here to adjust just the fill — the row's container/size is unaffected.
    private var activeBackgroundColor: Color {
        Palette.pine.opacity(0.4) // #165B05 at 40%
    }

    /// Scales a base font size to the device width so text reads consistently across
    /// screen sizes. `base` is the size on a 393pt-wide screen (iPhone 14/15); it
    /// grows/shrinks proportionally and is clamped to stay sane on small/large devices.
    private func scaledFontSize(base: CGFloat) -> CGFloat {
        let referenceWidth: CGFloat = 393
        let scaled = base * UIScreen.main.bounds.width / referenceWidth
        return min(max(scaled, base * 0.85), base * 1.4) // floor / ceiling
    }

    // The current player's row is bigger than everyone else's.
    private var nameFontSize: CGFloat { scaledFontSize(base: isCurrentTurn ? 38 : 26) }  // tweak base for name size
    private var scoreFontSize: CGFloat { scaledFontSize(base: isCurrentTurn ? 38 : 26) } // tweak base for score size

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
                .fill(isCurrentTurn ? activeBackgroundColor : Color.clear)

            // Progress bar (full bleed on left, top, bottom)
            GeometryReader { geometry in
                shape
                    .fill(progressBarColor)
                    .frame(width: geometry.size.width * progress)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Palette.lime)
                            .frame(width: 2)
                            .opacity(showsBarEdge ? 1 : 0)
                    }
                    .overlay(alignment: .trailing) {
                        ProgressTipGlow(progress: progress, isActive: isCurrentTurn)
                    }
                    .animation(.easeOut(duration: 0.6), value: progress)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    if isCurrentTurn {
                        cursor
                    }

                    if hasCrown {
                        crown
                    }

                    Text(player.name)
                        .modifier(AnimatableFont(name: "Jersey10-Regular", size: nameFontSize))
                        .foregroundColor(nameColor)

                    Spacer()

                    // Rolls up digit by digit, in step with the bar
                    Text(player.score, format: .number.grouping(.never))
                        .modifier(AnimatableFont(name: "Jersey10-Regular", size: scoreFontSize))
                        .foregroundColor(scoreColor)
                        .contentTransition(.numericText(value: Double(player.score)))
                        .animation(.easeOut(duration: 0.6), value: player.score)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named("game"))
                        } action: { frame in
                            onScoreFrame(frame)
                        }
                }

                if let pointsNeeded = pointsNeeded, isCurrentTurn {
                    Text("\(pointsNeeded) to win")
                        .font(.custom("Jersey10-Regular", size: 18))
                        .foregroundColor(nameColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isCurrentTurn ? 16 : 10)
        }
        .clipShape(shape)
        .overlay {
            ProgressBuildEmitter(progress: progress, isActive: isCurrentTurn)
                .allowsHitTesting(false)
        }
        // The winner glows gold while the result sinks in
        .overlay {
            Rectangle()
                .strokeBorder(Palette.gold, lineWidth: 2)
                .opacity(isWinner ? 1 : 0)
        }
        .shadow(color: Palette.gold.opacity(isWinner ? 0.65 : 0), radius: 22)
        .animation(.easeOut(duration: 0.35), value: isWinner)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isWinner ? "Winner" : (hasCrown ? "Leader" : ""))
        .accessibilityAddTraits(isCurrentTurn ? .isSelected : [])
    }

    @ViewBuilder
    private var cursor: some View {
        let cursor = PixelCursor(pixel: 3)
            // Nudges toward the name and back, like a menu cursor waiting on you
            .phaseAnimator(reduceMotion ? [0.0] : [0.0, 3.0]) { content, x in
                content.offset(x: x)
            } animation: { _ in
                .easeInOut(duration: 0.2).delay(0.3)
            }
            .transition(.opacity)
        if let cursorNamespace {
            cursor.matchedGeometryEffect(id: "cursor", in: cursorNamespace)
        } else {
            cursor
        }
    }

    @ViewBuilder
    private var crown: some View {
        let crown = PixelCrown(pixel: 2)
            .shadow(color: Palette.gold.opacity(isCurrentTurn && !isWinner ? 0 : 0.6), radius: 4)
            // Winner: the crown swells, then keeps a slow, proud bounce
            .keyframeAnimator(initialValue: 1.0, trigger: isWinner) { [isWinner] content, scale in
                content.scaleEffect(isWinner ? scale : 1, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.9, duration: 0.25, spring: .bouncy)
                    SpringKeyframe(1.5, duration: 0.3)
                    SpringKeyframe(1.7, duration: 0.3)
                    SpringKeyframe(1.5, duration: 0.3)
                }
            }
            .transition(.scale(scale: 0.2).combined(with: .opacity))
        if let crownNamespace {
            crown.matchedGeometryEffect(id: "crown", in: crownNamespace)
        } else {
            crown
        }
    }
}

/// A pixel arrow, like the cursor in an old game menu.
private struct PixelCursor: View {
    /// Size of one "pixel" in points; the arrow is 4 × 7 pixels.
    var pixel: CGFloat = 3

    private static let map = [
        "x...",
        "xx..",
        "xxx.",
        "xxxx",
        "xxx.",
        "xx..",
        "x...",
    ]

    var body: some View {
        Canvas { context, _ in
            for (y, row) in Self.map.enumerated() {
                for (x, cell) in row.enumerated() where cell == "x" {
                    let rect = CGRect(x: CGFloat(x) * pixel, y: CGFloat(y) * pixel, width: pixel, height: pixel)
                    context.fill(Path(rect), with: .color(Palette.lime))
                }
            }
        }
        .frame(width: 4 * pixel, height: 7 * pixel)
        .accessibilityHidden(true)
    }
}

/// A custom font whose size animates. Changing `.font` directly jumps between sizes.
private struct AnimatableFont: ViewModifier, Animatable {
    let name: String
    var size: CGFloat

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.font(.custom(name, size: size))
    }
}

/// A bright band riding the tip of the bar while it grows, then fading once it settles.
private struct ProgressTipGlow: View {
    let progress: Double
    let isActive: Bool

    @State private var glow = 0.0

    var body: some View {
        LinearGradient(colors: [.clear, Palette.mist], startPoint: .leading, endPoint: .trailing)
            .frame(width: 28)
            .opacity(glow)
            .allowsHitTesting(false)
            .onChange(of: progress) { oldValue, newValue in
                guard isActive, newValue > oldValue else { return }
                withAnimation(.easeOut(duration: 0.08)) { glow = 0.9 }
                withAnimation(.easeOut(duration: 0.5).delay(0.45)) { glow = 0 }
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

