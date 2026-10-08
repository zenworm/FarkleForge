//
//  OnboardingView.swift
//  FarkleForge
//
//  How to play, told by the animals. Four pages, one rule each, with a little roll
//  of the dice under every rule that plays it out (and keeps rolling, quietly).
//  Shown on first launch, skippable from any page, and in the game menu after that.
//

import SwiftUI

struct OnboardingView: View {
    /// Flipped once the onboarding has been finished or skipped.
    static let seenKey = "hasSeenOnboarding"

    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Int? = 0
    @State private var hasAppeared = false
    @State private var isLeaving = false
    /// The first page arrives in silence; sound starts once the player touches something.
    @State private var hasInteracted = false

    private let steps = OnboardingStep.all

    private var current: Int { page ?? 0 }
    private var isLastPage: Bool { current == steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .opacity(hasAppeared && !isLeaving ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(isLeaving ? 0 : 0.5), value: hasAppeared)

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(steps) { step in
                        OnboardingPage(
                            step: step,
                            isActive: step.id == current && !isLeaving,
                            isLoud: hasInteracted,
                            hasAppeared: hasAppeared
                        )
                        .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $page)
            .scrollIndicators(.hidden)
            .onScrollPhaseChange { _, phase in
                if phase == .interacting { hasInteracted = true }
            }
            .opacity(isLeaving ? 0 : 1)
            .offset(y: isLeaving ? -30 : 0)

            nextButton
                .opacity(isLeaving ? 0 : (hasAppeared ? 1 : 0))
                .offset(y: hasAppeared && !isLeaving ? 0 : 40)
        }
        // Same backdrop as the start screen, so finishing cross-fades into it seamlessly.
        .background {
            Color.clear
                .overlay {
                    Image("startBg")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                hasAppeared = true
            }
            #if DEBUG
            // `-onboardingPage 2` opens on a later page, for screenshots.
            let start = UserDefaults.standard.integer(forKey: "onboardingPage")
            if start > 0, steps.indices.contains(start) { page = start }
            // `-demo onboarding` taps through every page by itself, for recording.
            if UserDefaults.standard.string(forKey: "demo") == "onboarding" {
                for i in 1...steps.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 4.5) { advance() }
                }
            }
            #endif
        }
    }

    private var topBar: some View {
        HStack {
            pageDots
            Spacer()
            Button(action: finish) {
                Text("Skip")
                    .font(.custom("JetBrainsMono-Medium", size: 17))
                    .foregroundStyle(Palette.accent)
                    .underline()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SquishButtonStyle(scale: 0.9))
            // The last page's button already says where you're going.
            .opacity(isLastPage ? 0 : 1)
            .disabled(isLastPage)
            .animation(.easeOut(duration: 0.2), value: isLastPage)
        }
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .frame(height: 48)
    }

    /// Square pixels, the current one stretched into a little bar.
    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(steps) { step in
                Rectangle()
                    .fill(step.id == current ? Palette.accent : Color.white.opacity(0.28))
                    .frame(width: step.id == current ? 20 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(steps.count)")
    }

    private var nextButton: some View {
        Button(action: advance) {
            Text(isLastPage ? "Let's farkle" : "Next")
                .font(.custom("Daydream", size: 16))
                .foregroundStyle(Palette.ink)
                .contentTransition(.opacity)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Capsule())
        }
        .background(Palette.leaf, in: Capsule())
        .buttonStyle(SquishButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isLastPage)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func advance() {
        guard !isLastPage else {
            finish()
            return
        }
        hasInteracted = true
        SoundEngine.shared.play(.tick)
        Haptics.tap()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            page = current + 1
        }
    }

    private func finish() {
        guard !isLeaving else { return }
        SoundEngine.shared.play(isLastPage ? .start : .tick)
        Haptics.soft()
        // Everything floats off, then the start screen builds in behind it.
        withAnimation(.easeIn(duration: 0.3)) {
            isLeaving = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.35)) {
            onFinish()
        }
    }
}

// MARK: - Steps

private struct OnboardingStep: Identifiable {
    let id: Int
    let animal: Animal
    /// What the animal says when its page arrives. Poking it runs through its usual lines.
    let line: String
    let title: String
    let detail: Text
    var aside: Text? = nil
    let rolls: [DemoRoll]

    var lines: [String] { [line] + animal.lines.filter { $0 != line } }

    static var all: [OnboardingStep] {
        [
            OnboardingStep(
                id: 0,
                animal: animal("otter"),
                line: "Six dice. No fear.",
                title: "Roll six dice",
                detail: Text("Each roll, set aside at least \(lit("one scoring die")). Bank it, or roll the rest."),
                aside: Text("Nothing scores? \(Text("Farkle!").foregroundStyle(Palette.farkle)) Your turn's points are gone."),
                rolls: [
                    DemoRoll(faces: [4, 1, 3, 6, 2, 6], keep: [1], points: 100),
                    DemoRoll(faces: [2, 3, 4, 6, 6, 3], keep: [], points: nil),
                ]
            ),
            OnboardingStep(
                id: 1,
                animal: animal("fox"),
                line: "Fives are my favorite.",
                title: "Ones and fives",
                detail: Text("Every \(lit("1")) is worth \(lit("100")).\nEvery \(lit("5")) is worth \(lit("50"))."),
                aside: Text("Keep one, or keep them all."),
                rolls: [
                    DemoRoll(faces: [3, 1, 6, 5, 2, 6], keep: [1, 3], points: 150, showsDieValues: true),
                    DemoRoll(faces: [5, 2, 1, 4, 1, 6], keep: [0, 2, 4], points: 250, showsDieValues: true),
                ]
            ),
            OnboardingStep(
                id: 2,
                animal: animal("raccoon"),
                line: "Three of a kind? Mine now.",
                title: "Three of a kind",
                detail: Text("Three of a kind is worth its number \(lit("× 100")). Three 4s make \(lit("400"))."),
                aside: Text("Except three 1s. Those are worth \(lit("1,000"))."),
                rolls: [
                    DemoRoll(faces: [4, 2, 4, 6, 4, 3], keep: [0, 2, 4], points: 400),
                    DemoRoll(faces: [6, 3, 6, 2, 4, 6], keep: [0, 2, 5], points: 600),
                    DemoRoll(faces: [1, 3, 6, 1, 2, 1], keep: [0, 3, 5], points: 1000),
                ]
            ),
            OnboardingStep(
                id: 3,
                animal: animal("panther"),
                line: "I only play to win.",
                title: "The big run",
                detail: Text("Roll \(lit("1 through 6")) in a single roll for \(lit("2,000"))."),
                aside: Text("Bank your points. First to the target takes the crown."),
                rolls: [
                    // Kept in face order, so the plinks climb the scale as they line up.
                    DemoRoll(faces: [3, 6, 1, 5, 2, 4], keep: [2, 4, 0, 5, 3, 1], points: 2000, linesUp: true),
                ]
            ),
        ]
    }

    private static func animal(_ species: String) -> Animal {
        AnimalCatalog.all.first { $0.species == species } ?? AnimalCatalog.all[0]
    }

    /// The numbers that matter, in the same green as the start screen's choices.
    private static func lit(_ text: String) -> Text {
        Text(text).foregroundStyle(Palette.accent)
    }
}

private struct DemoRoll {
    let faces: [Int]
    /// The dice set aside, in the order they're picked up.
    let keep: [Int]
    /// Nil when nothing scores: a farkle.
    let points: Int?
    /// Floats each kept die's own value over it (ones and fives).
    var showsDieValues = false
    /// The kept dice shuffle into order (the run).
    var linesUp = false

    var spokenDescription: String {
        let rolled = faces.map(String.init).joined(separator: ", ")
        guard let points else {
            return "Example roll: \(rolled). Nothing scores, so that's a farkle."
        }
        let kept = keep.map { String(faces[$0]) }.joined(separator: ", ")
        return "Example roll: \(rolled). Set aside \(kept) for \(points) points."
    }
}

// MARK: - Page

private struct OnboardingPage: View {
    let step: OnboardingStep
    let isActive: Bool
    let isLoud: Bool
    let hasAppeared: Bool

    var body: some View {
        GeometryReader { geo in
            let metrics = PageMetrics(size: geo.size)
            // Fixed bands, so the animal, the words and the dice sit in the same
            // place on every page and only the content changes as you swipe.
            VStack(spacing: 0) {
                AnimalHost(animal: step.animal, lines: step.lines, isActive: isActive, diameter: metrics.diameter)
                    .frame(height: metrics.stageHeight, alignment: .bottom)
                    .modifier(Entrance(isVisible: hasAppeared, delay: 0.05, scale: 0.6))

                words(scale: metrics.fontScale)
                    .frame(height: metrics.textHeight, alignment: .top)
                    .padding(.top, metrics.gap)
                    .modifier(Entrance(isVisible: hasAppeared, delay: 0.16))

                DiceDemo(rolls: step.rolls, isActive: isActive, isLoud: isLoud, dieSize: metrics.dieSize)
                    .frame(height: metrics.diceHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func words(scale: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text(step.title)
                .font(.custom("Daydream", size: 22 * scale))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
            step.detail
                .font(.custom("JetBrainsMono-Medium", size: 17 * scale))
                .lineSpacing(3)
            if let aside = step.aside {
                aside
                    .font(.custom("JetBrainsMono-Medium", size: 14 * scale))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(2)
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 28)
    }
}

private struct PageMetrics {
    let size: CGSize

    /// Type scales with the screen width from a 393pt reference, like the start screen.
    var fontScale: CGFloat { size.width / 393 }
    var diameter: CGFloat { min(size.height * 0.22, 150) }
    /// The animal plus headroom for its speech bubble.
    var stageHeight: CGFloat { diameter + 60 }
    var textHeight: CGFloat { min(size.height * 0.3, 170) }
    var gap: CGFloat { size.height > 560 ? 24 : 12 }
    /// Six dice and five gaps of a fifth of a die.
    var dieSize: CGFloat { min(46, (size.width - 48) / 7) }
    /// Room above the dice for kept ones to lift, and below for the score.
    var diceHeight: CGFloat { dieSize * 1.8 + 64 }
}

/// Rises into place on first launch, just after whatever is above it.
private struct Entrance: ViewModifier {
    let isVisible: Bool
    var delay: Double = 0
    var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : scale)
            .offset(y: isVisible ? 0 : 14)
            .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(delay), value: isVisible)
    }
}

// MARK: - Animal

/// The page's host: a big version of the start screen bubble with something to say.
/// It rolls in with its page, bobs while you read, and talks back when poked.
private struct AnimalHost: View {
    let animal: Animal
    let lines: [String]
    let isActive: Bool
    let diameter: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lineIndex = 0
    @State private var isSpeaking = false
    @State private var pokes = 0
    @State private var bob = false

    private var line: String { lines[lineIndex % lines.count] }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                SpeechBubble(text: line)
                    .id(lineIndex)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .scaleEffect(isSpeaking ? 1 : 0.5, anchor: .bottom)
            .opacity(isSpeaking ? 1 : 0)

            AnimalPortrait(animal: animal, diameter: diameter)
                .keyframeAnimator(initialValue: Poke(), trigger: pokes) { content, value in
                    content
                        .scaleEffect(x: value.scaleX, y: value.scaleY, anchor: .bottom)
                        .rotationEffect(.degrees(value.angle))
                } keyframes: { _ in
                    KeyframeTrack(\.scaleX) {
                        SpringKeyframe(1.1, duration: 0.1)
                        SpringKeyframe(0.96, duration: 0.14)
                        SpringKeyframe(1.0, duration: 0.3)
                    }
                    KeyframeTrack(\.scaleY) {
                        SpringKeyframe(0.88, duration: 0.1)
                        SpringKeyframe(1.05, duration: 0.14)
                        SpringKeyframe(1.0, duration: 0.3)
                    }
                    KeyframeTrack(\.angle) {
                        LinearKeyframe(-4, duration: 0.1)
                        LinearKeyframe(3, duration: 0.12)
                        SpringKeyframe(0, duration: 0.3)
                    }
                }
                .offset(y: bob ? -4 : 3)
                .visualEffect { [reduceMotion] content, proxy in
                    // Rolls in with its page like a ball, and shrinks a touch on the way out.
                    let frame = proxy.frame(in: .scrollView(axis: .horizontal))
                    let width = max(proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 1, 1)
                    let travel = reduceMotion ? 0 : (frame.midX - width / 2) / width
                    return content
                        .rotationEffect(.degrees(travel * 50))
                        .scaleEffect(1 - min(abs(travel), 1) * 0.2)
                }
                .onTapGesture(perform: poke)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The \(animal.species)")
        .accessibilityValue(line)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { poke() }
        .task(id: isActive) {
            // Pipes up once the page has settled.
            guard isActive, !isSpeaking else { return }
            try? await Task.sleep(for: .seconds(0.55))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                isSpeaking = true
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.8)) {
                bob = true
            }
        }
    }

    private func poke() {
        pokes += 1
        SoundEngine.shared.play(.voice(animal.voice))
        Haptics.tap()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) {
            if isSpeaking { lineIndex += 1 }
            isSpeaking = true
        }
    }
}

private struct Poke {
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var angle: Double = 0
}

private struct AnimalPortrait: View {
    let animal: Animal
    let diameter: CGFloat

    var body: some View {
        Image(animal.portrait)
            .resizable()
            .scaledToFill()
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .topLeading) {
                // Glassy highlight, top-left, same as the start screen bubbles.
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: diameter * 0.4, height: diameter * 0.25)
                    .offset(x: diameter * 0.19, y: diameter * 0.11)
            }
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.32), lineWidth: 3)
            }
            .background {
                Circle()
                    .fill(.black.opacity(0.3))
                    .offset(y: 9)
                    .blur(radius: 12)
            }
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("JetBrainsMono-Medium", size: 15))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Palette.cream, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(alignment: .bottom) {
                SpeechTail()
                    .fill(Palette.cream)
                    .frame(width: 14, height: 8)
                    .offset(y: 7)
            }
    }
}

private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Dice

/// Rolls the page's example, sets aside the scoring dice, and shows what they're
/// worth, then rolls the next example. The first roll after arriving plays out loud;
/// the loops after it are silent. Tap the dice to roll again.
private struct DiceDemo: View {
    let rolls: [DemoRoll]
    let isActive: Bool
    let isLoud: Bool
    let dieSize: CGFloat

    private enum Outcome: Equatable {
        case points(Int)
        case farkle
    }

    private struct RunKey: Equatable {
        let isActive: Bool
        let replays: Int
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var roll: DemoRoll?
    @State private var faces = Array(repeating: 1, count: 6)
    /// Left-to-right order of the dice (they only move for the run).
    @State private var order = Array(0..<6)
    @State private var tilts = Array(repeating: 0.0, count: 6)
    @State private var hops = Array(repeating: CGFloat.zero, count: 6)
    @State private var isShown = false
    @State private var kept: Set<Int> = []
    @State private var outcome: Outcome?
    @State private var shakes = 0
    @State private var bursts = 0
    @State private var nextRoll = 0
    @State private var replays = 0
    @State private var handledReplays = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: dieSize * 0.2) {
                ForEach(order, id: \.self) { index in
                    die(index)
                }
            }
            .padding(.top, dieSize * 0.8)
            .farkleShake(trigger: shakes, enabled: !reduceMotion)

            ZStack {
                verdict
                if !reduceMotion {
                    PixelBurst(trigger: bursts)
                }
            }
            .frame(height: 50)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: rollAgain)
        .task(id: RunKey(isActive: isActive, replays: replays)) {
            await run()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(roll?.spokenDescription ?? "Example roll")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Rolls the next example.")
        .accessibilityAction { rollAgain() }
    }

    private func die(_ index: Int) -> some View {
        let isKept = kept.contains(index)
        return DemoDie(face: faces[index], look: look(for: index), size: dieSize)
            .overlay(alignment: .top) {
                if isKept, let value = dieValue(index) {
                    Text(value)
                        .font(.custom("GeistMono-Medium", size: 13))
                        .foregroundStyle(Palette.accent)
                        .fixedSize()
                        .offset(y: -22)
                        .transition(.scale(scale: 0.4, anchor: .bottom).combined(with: .opacity))
                }
            }
            .rotationEffect(.degrees(tilts[index]))
            .offset(y: hops[index] + (isKept ? -dieSize * 0.32 : 0))
            .scaleEffect(isShown ? 1 : 0.4)
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : -dieSize)
            .animation(.spring(response: 0.42, dampingFraction: 0.62).delay(Double(index) * 0.04), value: isShown)
    }

    @ViewBuilder
    private var verdict: some View {
        switch outcome {
        case .points(let points):
            Text(points.formatted())
                .font(.custom("GeistMono-Bold", size: 34))
                .foregroundStyle(Palette.accent)
                .shadow(color: Palette.accent.opacity(0.5), radius: 10)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
        case .farkle:
            // A tiny version of the game's farkle sticker.
            Text("Farkle!")
                .font(.custom("Daydream", size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Palette.farkle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-3))
                .transition(.sticker)
        case nil:
            EmptyView()
        }
    }

    private func look(for index: Int) -> DemoDie.Look {
        if outcome == .farkle { return .farkle }
        if kept.contains(index) { return .kept }
        return kept.isEmpty ? .plain : .dimmed
    }

    private func dieValue(_ index: Int) -> String? {
        guard roll?.showsDieValues == true else { return nil }
        switch faces[index] {
        case 1: return "100"
        case 5: return "50"
        default: return nil
        }
    }

    private func rollAgain() {
        if isActive { replays += 1 }
    }

    private func run() async {
        guard isActive else {
            // Swiped away mid-roll: let the dice come to rest.
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                tilts = Array(repeating: 0, count: 6)
                hops = Array(repeating: 0, count: 6)
            }
            return
        }
        let tapped = replays != handledReplays
        handledReplays = replays
        // Let the page settle before the first roll.
        guard await pause(tapped ? 0 : 0.45) else { return }
        var loud = tapped || isLoud
        while !Task.isCancelled {
            let next = rolls[nextRoll % rolls.count]
            nextRoll += 1
            await play(next, loud: loud)
            loud = false
        }
    }

    private func play(_ next: DemoRoll, loud: Bool) async {
        withAnimation(.easeOut(duration: 0.2)) {
            kept = []
            outcome = nil
        }
        roll = next
        if loud {
            SoundEngine.shared.play(.diceRoll)
            Haptics.soft(0.5)
        }

        // Tumble: the faces flicker while the dice rattle, then they land.
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isShown = true
            order = Array(0..<6)
        }
        for _ in 0..<(reduceMotion ? 0 : 6) {
            withAnimation(.spring(response: 0.12, dampingFraction: 0.6)) {
                faces = faces.map { _ in .random(in: 1...6) }
                tilts = tilts.map { _ in .random(in: -30...30) }
                hops = hops.map { _ in .random(in: -14...0) }
            }
            guard await pause(0.06) else { return }
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            faces = next.faces
            tilts = Array(repeating: 0, count: 6)
            hops = Array(repeating: 0, count: 6)
        }
        if loud { Haptics.rigid(0.5) }
        guard await pause(0.5) else { return }

        // Set aside the dice that score, each one plinking its own number on the keypad scale.
        for index in next.keep {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                _ = kept.insert(index)
            }
            if loud {
                SoundEngine.shared.play(.key(next.faces[index]))
                Haptics.tap()
            }
            guard await pause(next.keep.count > 3 ? 0.1 : 0.16) else { return }
        }
        if next.linesUp {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                order = order.sorted { faces[$0] < faces[$1] }
            }
            guard await pause(0.4) else { return }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            outcome = next.points.map(Outcome.points) ?? .farkle
        }
        if next.points == nil {
            shakes += 1
            if loud {
                SoundEngine.shared.playFarkle()
                Haptics.farkle()
            }
        } else {
            if next.linesUp { bursts += 1 }
            if loud {
                SoundEngine.shared.play(next.linesUp ? .winner : .coin)
                Haptics.soft()
            }
        }
        _ = await pause(next.points == nil ? 2.0 : 2.4)
    }

    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
    }
}

/// A chunky die with square pips, so it belongs with the pixel crowns.
private struct DemoDie: View {
    enum Look { case plain, kept, dimmed, farkle }

    let face: Int
    let look: Look
    let size: CGFloat

    private var top: Color {
        switch look {
        case .plain, .dimmed: return Palette.cream
        case .kept: return Palette.accent
        case .farkle: return Palette.farkle
        }
    }

    /// The darker band along the bottom edge that gives the die a little depth.
    private var side: Color {
        switch look {
        case .plain, .dimmed: return Color(red: 0.76, green: 0.8, blue: 0.66)
        case .kept: return Palette.leaf
        case .farkle: return Color(red: 0.7, green: 0.18, blue: 0.18)
        }
    }

    private var pip: Color { look == .farkle ? .white : Palette.ink }

    private var pips: [CGPoint] {
        let p = 0.27, m = 0.5, f = 0.73
        switch face {
        case 1: return [.init(x: m, y: m)]
        case 2: return [.init(x: f, y: p), .init(x: p, y: f)]
        case 3: return [.init(x: f, y: p), .init(x: m, y: m), .init(x: p, y: f)]
        case 4: return [.init(x: p, y: p), .init(x: f, y: p), .init(x: p, y: f), .init(x: f, y: f)]
        case 5: return [.init(x: p, y: p), .init(x: f, y: p), .init(x: m, y: m), .init(x: p, y: f), .init(x: f, y: f)]
        default: return [.init(x: p, y: p), .init(x: f, y: p), .init(x: p, y: m),
                         .init(x: f, y: m), .init(x: p, y: f), .init(x: f, y: f)]
        }
    }

    var body: some View {
        let corner = size * 0.22
        let faceHeight = size * 0.91
        let pipSize = (size * 0.16).rounded()
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(side)
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(top)
                .frame(height: faceHeight)
                .overlay(alignment: .topLeading) {
                    ForEach(Array(pips.enumerated()), id: \.offset) { _, point in
                        Rectangle()
                            .fill(pip)
                            .frame(width: pipSize, height: pipSize)
                            .offset(x: (point.x * size - pipSize / 2).rounded(),
                                    y: (point.y * faceHeight - pipSize / 2).rounded())
                    }
                }
        }
        .frame(width: size, height: size)
        .opacity(look == .dimmed ? 0.4 : 1)
        .shadow(color: look == .kept ? Palette.accent.opacity(0.55) : .black.opacity(0.28),
                radius: look == .kept ? 12 : 5, y: look == .kept ? 0 : 4)
    }
}

/// A pop of square confetti in crown colors, for the big score.
private struct PixelBurst: View {
    let trigger: Int

    private struct Piece {
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
    }

    private struct Flight {
        var progress: CGFloat = 0
        var opacity: Double = 0
    }

    private static let pieces: [Piece] = {
        let colors = [Palette.gold, Palette.accent, Palette.mist, Palette.ruby, Palette.leaf, Palette.goldShadow]
        return (0..<18).map { i in
            Piece(
                angle: Double(i) / 18 * 2 * .pi + (i.isMultiple(of: 2) ? 0.12 : -0.08),
                distance: [70, 104, 84, 118, 64, 96][i % 6],
                size: [5, 7, 6, 8][i % 4],
                color: colors[i % colors.count]
            )
        }
    }()

    var body: some View {
        ZStack {
            ForEach(Self.pieces.indices, id: \.self) { i in
                let piece = Self.pieces[i]
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .keyframeAnimator(initialValue: Flight(), trigger: trigger) { content, flight in
                        content
                            .offset(
                                x: cos(piece.angle) * piece.distance * flight.progress,
                                // Flattened, with a little gravity pulling it down at the end.
                                y: sin(piece.angle) * piece.distance * 0.6 * flight.progress
                                    + 30 * flight.progress * flight.progress
                            )
                            .opacity(flight.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.progress) {
                            SpringKeyframe(1, duration: 0.85, spring: .smooth(duration: 0.5))
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(1, duration: 0.02)
                            LinearKeyframe(1, duration: 0.45)
                            LinearKeyframe(0, duration: 0.38)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingView {}
}
