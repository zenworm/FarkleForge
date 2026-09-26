//
//  PixelBuildEmitter.swift
//  FarkleForge
//
//  A band of pixel particles that rides the leading edge of a bottom-to-top reveal,
//  so images look like they're being built from pixels. Used by the game intro and
//  by the celebration, where the fog gives way to the animal.
//

import SwiftUI

struct VerticalBuildEmitter: View {
    let progress: Double
    /// Matches the duration of whatever reveal this rides along with.
    var duration: TimeInterval = 1.0

    @State private var system = VerticalBuildParticleSystem()
    @State private var isRunning = false
    @State private var runGeneration = 0

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
            guard newValue > oldValue else { return }
            system.beginSweep(from: oldValue, to: newValue, duration: duration)
            isRunning = true
            runGeneration += 1
            let generation = runGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if generation == runGeneration {
                    isRunning = false
                }
            }
        }
    }
}

private final class VerticalBuildParticleSystem {
    struct Particle {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var age: TimeInterval
        let lifetime: TimeInterval
        let size: CGFloat
        let color: Color
        let gravity: CGFloat
    }

    private(set) var particles: [Particle] = []
    private var sweepStart: Double = 0
    private var sweepEnd: Double = 0
    private var sweepBeganAt: Date?
    private var lastUpdate: Date?

    private var sweepDuration: TimeInterval = 1.0

    private static let palette: [Color] = [
        Color(red: 233/255.0, green: 255/255.0, blue: 224/255.0), // #E9FFE0 very light
        Color(red: 185/255.0, green: 239/255.0, blue: 168/255.0), // #B9EFA8 light
        Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0), // #91DA7F mid
        Color(red: 96/255.0, green: 191/255.0, blue: 72/255.0),   // #60BF48 dark
        Color(red: 60/255.0, green: 110/255.0, blue: 45/255.0),   // deep
    ]

    func beginSweep(from: Double, to: Double, duration: TimeInterval) {
        sweepDuration = duration
        sweepStart = from
        sweepEnd = to
        sweepBeganAt = Date()
    }

    func update(at date: Date, canvasSize: CGSize, margin: CGFloat) {
        let dt = min(lastUpdate.map { date.timeIntervalSince($0) } ?? 0, 1.0 / 20.0)
        lastUpdate = date

        for index in particles.indices {
            particles[index].age += dt
            particles[index].vy += particles[index].gravity * dt
            particles[index].x += particles[index].vx * dt
            particles[index].y += particles[index].vy * dt
        }
        particles.removeAll { $0.age >= $0.lifetime }

        guard let beganAt = sweepBeganAt else { return }
        let t = date.timeIntervalSince(beganAt) / sweepDuration
        if t >= 1 {
            sweepBeganAt = nil
            return
        }
        let eased = 1 - pow(1 - t, 3)
        let canvasWidth = canvasSize.width - margin * 2
        let canvasHeight = canvasSize.height - margin * 2
        let currentProgress = sweepStart + (sweepEnd - sweepStart) * eased
        let edgeY = margin + canvasHeight * (1 - currentProgress)

        // --- Coverage knobs: raise these to hide more of the gradient fade band ---
        let columns = 80              // horizontal density
        let layers = 3                // particles stacked per column to fill the band
        let bandHeight: CGFloat = 80  // how far BELOW the reveal edge to fill (covers the fade)
        let topOverscan: CGFloat = 12 // a little coverage ABOVE the edge too
        // --------------------------------------------------------------------------

        // A vertical band of particles trailing the leading edge as it climbs,
        // dense enough to mask the soft gradient reveal beneath it.
        for i in 0..<columns {
            let normalized = (CGFloat(i) + 0.5) / CGFloat(columns)
            for _ in 0..<layers {
                let x = margin + canvasWidth * normalized + .random(in: -5...5)
                let y = edgeY + .random(in: -topOverscan ... bandHeight)
                particles.append(
                    Particle(
                        x: x,
                        y: y,
                        vx: .random(in: -6...6),
                        vy: .random(in: -10...4),
                        age: 0,
                        lifetime: .random(in: 0.22...0.42),
                        size: [5, 6, 6, 7, 8].randomElement()!,
                        color: Self.palette.randomElement()!,
                        gravity: 0
                    )
                )
            }
        }
    }
}
