//
//  AnimalBubbleField.swift
//  FarkleForge
//
//  The start screen's cast: a bubble for every animal you might meet this game, plus
//  a few crown-only mystery bubbles for the ones still on their way. They drift in
//  the open space under the setup sentence, bump softly into each other, can be
//  grabbed and flung, and talk when poked.
//
//  Everything is one Canvas driven by a tiny physics step, so a handful of bubbles
//  costs about the same as one.
//

import SwiftUI

struct AnimalBubbleField: View {
    /// The open space the bubbles live in, in global coordinates. They can be dragged
    /// anywhere, but drift back home when let go.
    var habitat: CGRect
    /// When true the bubbles float up and away (the start game transition).
    var isLeaving: Bool
    /// Any touch on the field (used to dismiss the keyboard).
    var onTouch: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var simulation = BubbleSimulation()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                simulation.step(
                    to: timeline.date,
                    size: size,
                    habitat: habitat,
                    leaving: isLeaving,
                    calm: reduceMotion
                )
                simulation.draw(in: &context)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !simulation.isTouching { onTouch() }
                    simulation.touchMoved(to: value.location, start: value.startLocation)
                }
                .onEnded { value in
                    simulation.touchEnded(at: value.location, start: value.startLocation, velocity: value.velocity)
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Animals you might meet: \(AnimalCatalog.all.map(\.species).joined(separator: ", ")), and more on the way")
    }
}

// MARK: - Simulation

private final class BubbleSimulation {
    struct Bubble {
        enum Kind {
            case animal(Animal)
            case mystery
        }

        let kind: Kind
        let baseRadius: CGFloat
        var radius: CGFloat
        var position: CGPoint
        var velocity: CGVector = .zero
        let phase: Double
        /// Squash-and-stretch spring: 0 at rest, positive = squashed.
        var squish: CGFloat = 0
        var squishVelocity: CGFloat = 0
        var speech: Speech?
        var lineIndex = 0
        var opacity: Double = 1

        var lines: [String] {
            switch kind {
            case .animal(let animal): return animal.lines
            case .mystery: return AnimalCatalog.mysteryLines
            }
        }

        var voice: AnimalVoice {
            switch kind {
            case .animal(let animal): return animal.voice
            case .mystery: return .mystery
            }
        }
    }

    struct Speech {
        let text: String
        let born: Date
    }

    private(set) var bubbles: [Bubble] = []
    private(set) var isTouching = false
    private var grabbed: Int?
    private var isDragging = false
    private var grabOffset: CGVector = .zero
    private var touchBegan: Date?
    private var lastUpdate: Date?
    private var now = Date()
    private var nextChatter = Date().addingTimeInterval(6)
    private var lastBump = Date.distantPast
    private var fieldSize: CGSize = .zero

    private static let speechDuration: TimeInterval = 1.9

    // MARK: Setup

    private func populate(in habitat: CGRect) {
        var specs: [(Bubble.Kind, CGFloat)] = AnimalCatalog.all.enumerated().map { index, animal in
            (.animal(animal), [46, 40, 44, 38, 42][index % 5])
        }
        specs += (0..<AnimalCatalog.mysteryCount).map { index in (.mystery, [28, 25, 31][index % 3]) }
        specs.shuffle()

        bubbles = specs.enumerated().map { index, spec in
            let column = CGFloat(index % 4) + 0.5
            let x = habitat.minX + habitat.width * column / 4 + .random(in: -20...20)
            // Start below the habitat and staggered, so they rise into view one by one.
            let y = habitat.maxY + spec.1 + 10 + CGFloat(index) * 22
            return Bubble(
                kind: spec.0,
                baseRadius: spec.1,
                radius: spec.1,
                position: CGPoint(x: x, y: y),
                velocity: .zero,
                phase: .random(in: 0...(2 * .pi))
            )
        }
    }

    // MARK: Step

    func step(to date: Date, size: CGSize, habitat rawHabitat: CGRect, leaving: Bool, calm: Bool) {
        now = date
        fieldSize = size
        let dt = CGFloat(min(lastUpdate.map { date.timeIntervalSince($0) } ?? 0, 1.0 / 30.0))
        lastUpdate = date

        // Wait for layout to report where the open space is before anyone appears.
        guard !rawHabitat.isEmpty, size.width > 0 else { return }
        let habitat = rawHabitat.insetBy(dx: 12, dy: 0)
        if bubbles.isEmpty { populate(in: habitat) }

        // Shrink everyone a little if the habitat gets cramped (lots of players
        // makes the sentence taller), so they never have to pile up.
        let totalArea = bubbles.reduce(0) { $0 + .pi * $1.baseRadius * $1.baseRadius }
        let fit = min(1, sqrt(habitat.width * habitat.height * 0.34 / max(totalArea, 1)))
        let t = date.timeIntervalSinceReferenceDate

        for i in bubbles.indices {
            var b = bubbles[i]
            let breathing = 1 + 0.018 * CGFloat(sin(t * 1.3 + b.phase))
            b.radius += (b.baseRadius * max(fit, 0.6) * breathing - b.radius) * min(1, 6 * dt)

            // Squash-and-stretch spring
            let accel = -320 * b.squish - 11 * b.squishVelocity
            b.squishVelocity += accel * dt
            b.squish += b.squishVelocity * dt

            if leaving {
                b.velocity.dy -= 4200 * dt
                b.opacity = max(0, b.opacity - Double(dt) * 1.4)
            } else if i != grabbed {
                // Wander: each bubble chases its own slow, looping drift.
                let wander = calm ? CGVector.zero : CGVector(
                    dx: cos(t * 0.31 + b.phase) * 16,
                    dy: sin(t * 0.43 + b.phase * 1.7) * 12
                )
                let relax = 1 - exp(-0.9 * dt)
                b.velocity.dx += (wander.dx - b.velocity.dx) * relax
                b.velocity.dy += (wander.dy - b.velocity.dy) * relax

                // Soft walls: a critically damped spring eases anything outside the
                // habitat back in, fast but without overshooting into the text.
                let r = b.radius
                let k: CGFloat = 20
                let damping = 2 * sqrt(k)
                let outX = max(habitat.minX - (b.position.x - r), 0) - max(b.position.x + r - habitat.maxX, 0)
                let outY = max(habitat.minY - (b.position.y - r), 0) - max(b.position.y + r - habitat.maxY, 0)
                if outX != 0 { b.velocity.dx += (outX * k - b.velocity.dx * damping) * dt }
                if outY != 0 { b.velocity.dy += (outY * k - b.velocity.dy * damping) * dt }

                // Speed limit, so a wild fling still reads as floating.
                let speed = hypot(b.velocity.dx, b.velocity.dy)
                if speed > 1400 {
                    b.velocity.dx *= 1400 / speed
                    b.velocity.dy *= 1400 / speed
                }
            }

            if i != grabbed {
                b.position.x += b.velocity.dx * dt
                b.position.y += b.velocity.dy * dt
            }

            if let speech = b.speech, date.timeIntervalSince(speech.born) > Self.speechDuration {
                b.speech = nil
            }
            bubbles[i] = b
        }

        if !leaving { resolveCollisions(dt: dt) }
        if !leaving && !calm { chatter() }
    }

    private func resolveCollisions(dt: CGFloat) {
        for i in bubbles.indices {
            for j in (i + 1)..<bubbles.count {
                // Personal space: a gentle push well before contact, so the group
                // spreads out to fill the open space instead of huddling.
                let dx = bubbles[j].position.x - bubbles[i].position.x
                let dy = bubbles[j].position.y - bubbles[i].position.y
                let distance = max(hypot(dx, dy), 0.001)
                let comfort = bubbles[i].radius + bubbles[j].radius + 44
                guard distance < comfort else { continue }
                let push = (comfort - distance) * 2.2 * dt
                if i != grabbed {
                    bubbles[i].velocity.dx -= dx / distance * push
                    bubbles[i].velocity.dy -= dy / distance * push
                }
                if j != grabbed {
                    bubbles[j].velocity.dx += dx / distance * push
                    bubbles[j].velocity.dy += dy / distance * push
                }
            }
        }
        for i in bubbles.indices {
            for j in (i + 1)..<bubbles.count {
                let dx = bubbles[j].position.x - bubbles[i].position.x
                let dy = bubbles[j].position.y - bubbles[i].position.y
                let distance = max(hypot(dx, dy), 0.001)
                let minDistance = bubbles[i].radius + bubbles[j].radius + 6
                guard distance < minDistance else { continue }

                let nx = dx / distance, ny = dy / distance
                let overlap = minDistance - distance
                // A held bubble is an immovable object; everyone else shares the push.
                let shareI: CGFloat = i == grabbed ? 0 : (j == grabbed ? 1 : 0.5)
                let shareJ: CGFloat = 1 - shareI
                bubbles[i].position.x -= nx * overlap * shareI
                bubbles[i].position.y -= ny * overlap * shareI
                bubbles[j].position.x += nx * overlap * shareJ
                bubbles[j].position.y += ny * overlap * shareJ

                let approach = (bubbles[i].velocity.dx - bubbles[j].velocity.dx) * nx
                    + (bubbles[i].velocity.dy - bubbles[j].velocity.dy) * ny
                guard approach > 0 else { continue }
                let impulse = approach * 0.8
                if i != grabbed {
                    bubbles[i].velocity.dx -= nx * impulse * (j == grabbed ? 2 : 1)
                    bubbles[i].velocity.dy -= ny * impulse * (j == grabbed ? 2 : 1)
                }
                if j != grabbed {
                    bubbles[j].velocity.dx += nx * impulse * (i == grabbed ? 2 : 1)
                    bubbles[j].velocity.dy += ny * impulse * (i == grabbed ? 2 : 1)
                }
                if approach > 140 {
                    let jiggle = min(approach / 900, 0.35)
                    bubbles[i].squishVelocity += jiggle * 6
                    bubbles[j].squishVelocity += jiggle * 6
                    if now.timeIntervalSince(lastBump) > 0.09 {
                        lastBump = now
                        SoundEngine.shared.play(.bubbleBump, volume: Float(min(1, approach / 600)))
                    }
                }
            }
        }
    }

    /// Every so often, when nobody's playing with them, an animal pipes up on its
    /// own. Silently: the start screen shouldn't make noise unless you touch it.
    private func chatter() {
        guard !isTouching, now >= nextChatter, !bubbles.isEmpty else { return }
        nextChatter = now.addingTimeInterval(.random(in: 6...10))
        let candidates = bubbles.indices.filter { bubbles[$0].speech == nil }
        guard let index = candidates.randomElement() else { return }
        speak(index, withSound: false)
    }

    private func speak(_ index: Int, withSound: Bool) {
        let lines = bubbles[index].lines
        bubbles[index].speech = Speech(text: lines[bubbles[index].lineIndex % lines.count], born: now)
        bubbles[index].lineIndex += 1
        bubbles[index].squishVelocity += 7
        if withSound {
            SoundEngine.shared.play(.voice(bubbles[index].voice))
        }
    }

    // MARK: Touch

    func touchMoved(to location: CGPoint, start: CGPoint) {
        let date = Date()
        if !isTouching {
            isTouching = true
            touchBegan = date
            // Topmost (largest, drawn last) bubble under the finger wins.
            grabbed = drawOrder.reversed().first { index in
                let b = bubbles[index]
                return hypot(b.position.x - location.x, b.position.y - location.y) < b.radius + 8
            }
            if let grabbed {
                let b = bubbles[grabbed]
                grabOffset = CGVector(dx: b.position.x - location.x, dy: b.position.y - location.y)
                bubbles[grabbed].squishVelocity -= 4
            }
        }
        guard let grabbed else { return }

        if !isDragging && hypot(location.x - start.x, location.y - start.y) > 8 {
            isDragging = true
            SoundEngine.shared.play(.bubbleGrab)
            Haptics.soft(0.5)
        }
        let target = CGPoint(x: location.x + grabOffset.dx, y: location.y + grabOffset.dy)
        let previous = bubbles[grabbed].position
        bubbles[grabbed].position = target
        // Remember the motion so collisions push others the right way.
        bubbles[grabbed].velocity = isDragging
            ? CGVector(dx: (target.x - previous.x) * 60, dy: (target.y - previous.y) * 60)
            : .zero
    }

    func touchEnded(at location: CGPoint, start: CGPoint, velocity: CGSize) {
        defer {
            isTouching = false
            isDragging = false
            grabbed = nil
            nextChatter = Date().addingTimeInterval(.random(in: 6...10))
        }
        guard let grabbed else { return }

        let moved = hypot(location.x - start.x, location.y - start.y)
        let held = Date().timeIntervalSince(touchBegan ?? Date())
        if moved < 10 && held < 0.4 {
            // A poke: squish and say something.
            bubbles[grabbed].velocity = .zero
            speak(grabbed, withSound: true)
            Haptics.tap()
        } else {
            // A fling.
            bubbles[grabbed].velocity = CGVector(dx: velocity.width, dy: velocity.height)
            bubbles[grabbed].squishVelocity += 3
        }
    }

    // MARK: Drawing

    private var drawOrder: [Int] {
        bubbles.indices.sorted { bubbles[$0].baseRadius < bubbles[$1].baseRadius }
    }

    func draw(in context: inout GraphicsContext) {
        let order = drawOrder
        for index in order {
            drawBubble(bubbles[index], in: &context)
        }
        // Speech on top of every bubble.
        for index in order {
            if let speech = bubbles[index].speech {
                drawSpeech(speech, for: bubbles[index], in: &context)
            }
        }
    }

    private func drawBubble(_ b: Bubble, in context: inout GraphicsContext) {
        guard b.opacity > 0 else { return }
        let squish = max(-0.25, min(b.squish, 0.25))
        var layer = context
        layer.opacity = b.opacity
        layer.translateBy(x: b.position.x, y: b.position.y)
        layer.scaleBy(x: 1 + squish, y: 1 - squish)

        let r = b.radius
        let circle = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

        // Soft drop shadow
        layer.drawLayer { shadow in
            shadow.addFilter(.blur(radius: 10))
            shadow.fill(Path(ellipseIn: circle.offsetBy(dx: 0, dy: 7)), with: .color(.black.opacity(0.3)))
        }

        layer.drawLayer { inner in
            inner.clip(to: Path(ellipseIn: circle))
            switch b.kind {
            case .animal(let animal):
                inner.draw(Image(animal.portrait), in: circle)
            case .mystery:
                inner.fill(Path(circle), with: .color(Palette.forest.opacity(0.92)))
                // An empty crown, waiting for its animal.
                let pixel = (r * 0.11).rounded(.down).clamped(to: 2...5)
                let crownWidth = CGFloat(PixelCrown.columns) * pixel
                let crownHeight = CGFloat(PixelCrown.rows) * pixel
                PixelCrown.draw(in: &inner, origin: CGPoint(x: -crownWidth / 2, y: -r * 0.2 - crownHeight),
                                pixel: pixel, tint: Palette.accent, opacity: 0.55)
                let mark = inner.resolve(
                    Text("?").font(.custom("Daydream", size: r * 0.62)).foregroundStyle(Palette.accent.opacity(0.9))
                )
                inner.draw(mark, at: CGPoint(x: 0, y: r * 0.3))
            }
            // Glassy highlight, top-left
            let gloss = CGRect(x: -r * 0.62, y: -r * 0.78, width: r * 0.8, height: r * 0.5)
            inner.fill(
                Path(ellipseIn: gloss),
                with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.4), .white.opacity(0)]),
                    startPoint: CGPoint(x: gloss.midX, y: gloss.minY),
                    endPoint: CGPoint(x: gloss.midX, y: gloss.maxY)
                )
            )
        }

        // Rim
        layer.stroke(Path(ellipseIn: circle.insetBy(dx: 1.25, dy: 1.25)),
                     with: .color(.white.opacity(0.32)), lineWidth: 2.5)
    }

    private func drawSpeech(_ speech: Speech, for b: Bubble, in context: inout GraphicsContext) {
        let age = now.timeIntervalSince(speech.born)
        // Pop in with overshoot, hang around, then shrink away.
        let appear = min(age / 0.28, 1)
        let c1 = 2.2, c3 = c1 + 1
        var scale = 1 + c3 * pow(appear - 1, 3) + c1 * pow(appear - 1, 2)
        var opacity = min(age / 0.08, 1)
        let exit = age - (Self.speechDuration - 0.22)
        if exit > 0 {
            let x = min(exit / 0.22, 1)
            scale *= 1 - 0.3 * x
            opacity *= 1 - x
        }
        opacity *= b.opacity

        let text = context.resolve(
            Text(speech.text)
                .font(.custom("JetBrainsMono-Medium", size: 13))
                .foregroundStyle(Palette.ink)
        )
        let textSize = text.measure(in: CGSize(width: 200, height: 60))
        let padding = CGSize(width: 12, height: 8)
        let pill = CGSize(width: textSize.width + padding.width * 2, height: textSize.height + padding.height * 2)

        // Above the bubble unless that would run off the top; then below.
        let above = b.position.y - b.radius - pill.height - 12 > 60
        let anchor = CGPoint(x: b.position.x, y: above ? b.position.y - b.radius - 6 : b.position.y + b.radius + 6)
        var centerX = anchor.x
        centerX = min(max(centerX, pill.width / 2 + 10), fieldSize.width - pill.width / 2 - 10)
        let centerY = above ? anchor.y - 8 - pill.height / 2 : anchor.y + 8 + pill.height / 2

        var layer = context
        layer.opacity = opacity
        layer.translateBy(x: anchor.x, y: anchor.y)
        layer.scaleBy(x: scale, y: scale)
        layer.translateBy(x: -anchor.x, y: -anchor.y)

        let rect = CGRect(x: centerX - pill.width / 2, y: centerY - pill.height / 2, width: pill.width, height: pill.height)
        var tail = Path()
        let tailX = min(max(anchor.x, rect.minX + 14), rect.maxX - 14)
        if above {
            tail.move(to: CGPoint(x: tailX - 6, y: rect.maxY - 1))
            tail.addLine(to: CGPoint(x: tailX, y: rect.maxY + 7))
            tail.addLine(to: CGPoint(x: tailX + 6, y: rect.maxY - 1))
        } else {
            tail.move(to: CGPoint(x: tailX - 6, y: rect.minY + 1))
            tail.addLine(to: CGPoint(x: tailX, y: rect.minY - 7))
            tail.addLine(to: CGPoint(x: tailX + 6, y: rect.minY + 1))
        }
        layer.fill(Path(roundedRect: rect, cornerRadius: 12, style: .continuous), with: .color(Palette.cream))
        layer.fill(tail, with: .color(Palette.cream))
        layer.draw(text, at: CGPoint(x: rect.midX, y: rect.midY))
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
