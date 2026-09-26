//
//  ContentView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.videoCache) private var videoCache
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SoundEngine.enabledKey) private var soundEnabled = true
    @Namespace private var crownNamespace

    @State private var currentInput = ""
    @State private var showingPlayerList = false
    @State private var showingResetAlert = false
    @State private var showingRulesSheet = false
    @State private var showingCelebration = false
    /// The game's chrome (rows, keypad, header) steps aside so the celebration can
    /// build the animal directly over the live background.
    @State private var isCelebrating = false
    @State private var gameVideoURL: URL? = nil
    @State private var gameImageName: String? = nil
    @State private var isBanking = false
    @State private var isIntroRevealed = false
    @State private var showContent: Bool = false
    @State private var hasPlayedIntro: Bool = false

    // The game's big beats
    @State private var farkleCount = 0
    @State private var farkleLines = FarkleLines()
    @State private var farkleStreaks: [UUID: Int] = [:]
    @State private var sticker: GameSticker? = nil
    @State private var stickerTask: Task<Void, Never>? = nil
    @State private var stickerTilt: Double = -3
    @State private var crownHolder: UUID? = nil

    // The banked number's flight from the display up to the player's score
    @State private var flight: ScoreFlight? = nil
    @State private var geometry = GameGeometry()

    #if DEBUG
    @State private var showingSoundLab = false
    #endif

    var body: some View {
        Group {
            if gameState.players.isEmpty {
                StartGameView()
                    .transition(.opacity)
            } else {
                // Game view - with navigation
                NavigationStack {
                    gameInProgressView
                        .navigationTitle("What The Farkle")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbar {
                            toolbarContent
                        }
                        .sheet(isPresented: $showingPlayerList) {
                            PlayerListView()
                        }
                        .sheet(isPresented: $showingRulesSheet) {
                            FarkleRulesView()
                        }
                        #if DEBUG
                        .sheet(isPresented: $showingSoundLab) {
                            SoundLabView()
                        }
                        #endif
                        .alert("New game", isPresented: $showingResetAlert) {
                            Button("Cancel", role: .cancel) { }
                            Button("New game", role: .destructive) {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    gameState.resetGame()
                                }
                                currentInput = ""
                            }
                        } message: {
                            Text("This will remove all players and reset the game. Are you sure?")
                        }
                        .onChange(of: gameState.winner) { _, newValue in
                            guard newValue != nil else { return }
                            // Let the winning bar finish its sweep before the fog clears.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                guard gameState.winner != nil else { return }
                                // Clear the stage, leaving only the fog...
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isCelebrating = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    // ...then present over it. The celebration has a clear
                                    // background and builds itself in, so no sheet slide.
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        showingCelebration = true
                                    }
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showingCelebration, onDismiss: {
                            gameState.resetScores()
                            crownHolder = nil
                            farkleStreaks = [:]
                            // The next game's background builds in, then the chrome returns.
                            isCelebrating = false
                            isIntroRevealed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showContent = true
                                }
                            }
                        }) {
                            celebrationOverlay
                                .presentationBackground(.clear)
                        }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: gameState.players.isEmpty) { _, isEmpty in
            if isEmpty {
                hasPlayedIntro = false
                isIntroRevealed = false
                showContent = false
                crownHolder = nil
                farkleStreaks = [:]
                // Clear the background so the next game deals a fresh one from the
                // shuffle bag; ContentView's @State persists across the reset, so
                // without this the onAppear guard would reuse the previous image.
                gameVideoURL = nil
                gameImageName = nil
            }
        }
    }

    private var currentAnimal: Animal? {
        AnimalCatalog.animal(forBackground: gameImageName)
    }

    /// How close the leader is to winning, eased so the background creeps toward the
    /// animal slowly at first and leans in hard at the end.
    private var revealProgress: Double {
        let target = Double(max(gameState.targetScore, 1))
        return pow(min(Double(gameState.leaderScore) / target, 1), 1.4)
    }

    private var gameInProgressView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                                PlayerRowView(
                                    player: player,
                                    isCurrentTurn: player.id == gameState.currentPlayer?.id,
                                    isFinalRound: gameState.isFinalRound,
                                    leaderScore: gameState.leaderScore,
                                    targetScore: gameState.targetScore,
                                    isFirst: index == 0,
                                    isLast: index == gameState.players.count - 1,
                                    hasCrown: player.id == crownHolder,
                                    crownNamespace: crownNamespace
                                ) { frame in
                                    self.geometry.scoreFrames[player.id] = frame
                                }
                                .id(player.id)
                            }
                        }
                        .padding(.horizontal)
                        // Half a viewport of headroom on each end so any row,
                        // including the first and last, can scroll to exact center
                        .padding(.vertical, geometry.size.height / 2)
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled()
                    .scrollEdgeEffectHidden(true, for: .top)
                    .mask {
                        VStack(spacing: 0) {
                            // Long fade from the very top of the screen so rows
                            // dissolve as they scroll up behind the header
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                .frame(height: 110)
                            Rectangle()
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 32)
                        }
                        .ignoresSafeArea(edges: .top)
                    }
                }
                .onChange(of: gameState.currentTurnIndex) { oldValue, newValue in
                    if let currentPlayer = gameState.currentPlayer {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            proxy.scrollTo(currentPlayer.id, anchor: .center)
                        }
                    }
                }
                .onAppear {
                    if let currentPlayer = gameState.currentPlayer {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(currentPlayer.id, anchor: .center)
                        }
                    }
                }
            }
            .opacity(showContent ? 1 : 0)
            // Low in the list, just above the display: the active row is always
            // centered, so this never covers whose turn it is now.
            .overlay(alignment: .bottom) {
                if let sticker {
                    StickerView(sticker: sticker)
                        .id(sticker.id)
                        .transition(.sticker)
                        .padding(.bottom, 4)
                        .allowsHitTesting(false)
                }
            }

            ScoreInputView(
                currentInput: $currentInput,
                isDisplayHidden: flight != nil,
                onSubmit: bank,
                onFarkle: farkle,
                onDisplayFrame: { geometry.displayFrame = $0 }
            )
            .opacity(showContent ? 1 : 0)
        }
        .opacity(isCelebrating ? 0 : 1)
        .farkleShake(trigger: farkleCount, enabled: !reduceMotion)
        .coordinateSpace(.named("game"))
        .overlay {
            if let flight {
                ScoreFlightView(flight: flight)
                    // Lands with a little poof as the score starts rolling
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
            }
        }
        .overlay {
            FarkleVignette(trigger: farkleCount)
        }
        .background {
            ZStack {
                Palette.forest
                if let name = gameImageName {
                    // The background builds itself up out of its own pixels.
                    PixelBuildReveal(isRevealed: isIntroRevealed, duration: 1.0, colorSource: .image(name)) {
                        FogBackdrop(imageName: name, closeness: revealProgress)
                            .animation(.easeInOut(duration: 1.6), value: revealProgress)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if gameImageName == nil {
                let selection = videoCache.selectForNewGame()
                gameVideoURL = selection.url
                gameImageName = selection.name
            }
            updateCrown()
            if !hasPlayedIntro {
                hasPlayedIntro = true
                isIntroRevealed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showContent = true
                    }
                }
                #if DEBUG
                DemoScript.run(on: self)
                #endif
            }
        }
    }

    // MARK: - Banking

    fileprivate func bank(_ score: Int) {
        guard !isBanking, let player = gameState.currentPlayer else { return }
        isBanking = true
        SoundEngine.shared.play(.coin)
        Haptics.soft()

        let text = currentInput.isEmpty ? String(score) : currentInput
        guard !reduceMotion,
              let target = geometry.scoreFrames[player.id], target != .zero,
              geometry.displayFrame != .zero else {
            currentInput = ""
            land(score, for: player.id)
            return
        }

        // Toss the typed number up to the player's score. Horizontal and vertical
        // motion use different curves, which bends the path into a little arc.
        flight = ScoreFlight(text: text, from: geometry.displayFrame.center, to: target.center)
        currentInput = ""
        withAnimation(.easeIn(duration: 0.3)) {
            flight?.arrivedX = true
        }
        withAnimation(.timingCurve(0.2, 0.7, 0.4, 1, duration: 0.3)) {
            flight?.arrivedY = true
        } completion: {
            withAnimation(.easeOut(duration: 0.18)) {
                flight = nil
            }
            land(score, for: player.id)
        }
    }

    private func land(_ score: Int, for playerId: UUID) {
        guard let before = gameState.players.first(where: { $0.id == playerId }) else {
            isBanking = false
            return
        }
        let wasFinalRound = gameState.isFinalRound
        let target = Double(max(gameState.targetScore, 1))
        let fromProgress = min(Double(before.score) / target, 1)
        let toProgress = min(Double(before.score + score) / target, 1)

        var crownChanged = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
            gameState.applyBankedScore(score, to: playerId)
            crownChanged = updateCrown()
        }
        farkleStreaks[playerId] = 0

        // The fill arpeggio and haptic ticks ride the bar as it sweeps.
        SoundEngine.shared.play(.fill(from: fromProgress, to: toProgress))
        Haptics.fill(steps: Synth.fillSteps(from: fromProgress, to: toProgress), duration: 0.6)

        if crownChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                SoundEngine.shared.play(.crown)
                Haptics.rigid(0.6)
            }
        }

        if !wasFinalRound && gameState.isFinalRound && gameState.winner == nil,
           let leader = gameState.players.first(where: { $0.id == gameState.finalRoundTriggerPlayerId }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                SoundEngine.shared.play(.finalRound)
                Haptics.success()
                showSticker(style: .finalRound, title: "Final round", message: "Beat \(leader.name)'s \(leader.score.formatted())")
            }
        }

        // Let the progress bar animation play before the turn moves on
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                gameState.advanceTurn()
            }
            isBanking = false
        }
    }

    // MARK: - Farkles

    fileprivate func farkle() {
        guard !isBanking, let player = gameState.currentPlayer else { return }

        let streak = (farkleStreaks[player.id] ?? 0) + 1
        farkleStreaks[player.id] = streak
        let line = farkleLines.next(name: player.name, animal: currentAnimal?.species, streak: streak)

        farkleCount += 1
        SoundEngine.shared.playFarkle()
        Haptics.farkle()
        showSticker(style: .farkle, title: streak > 1 ? "Farkle ×\(streak)" : "Farkle!", message: line)

        withAnimation(.easeIn(duration: 0.18)) {
            currentInput = ""
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            gameState.farkle()
        }
    }

    private func undo() {
        SoundEngine.shared.play(.undo)
        Haptics.soft(0.6)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            gameState.undoLastScoreEntry()
            updateCrown()
        }
        // If the undone entry was a farkle, it no longer counts toward the streak.
        if let id = gameState.currentPlayer?.id {
            farkleStreaks[id] = max(0, (farkleStreaks[id] ?? 0) - 1)
        }
        currentInput = ""
    }

    private func showSticker(style: GameSticker.Style, title: String, message: String) {
        stickerTilt = stickerTilt < 0 ? .random(in: 2...3.5) : -.random(in: 2...3.5)
        stickerTask?.cancel()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
            sticker = GameSticker(style: style, title: title, message: message, tilt: stickerTilt)
        }
        stickerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(style == .farkle ? 1.7 : 2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.22)) {
                sticker = nil
            }
        }
    }

    /// The crown goes to the outright leader. On a tie it stays where it is, so the
    /// only way to take it is to pass the holder.
    @discardableResult
    private func updateCrown() -> Bool {
        let top = gameState.players.map(\.score).max() ?? 0
        let newHolder: UUID?
        if top <= 0 {
            newHolder = nil
        } else if let holder = crownHolder,
                  gameState.players.first(where: { $0.id == holder })?.score == top {
            newHolder = holder
        } else {
            newHolder = gameState.players.first { $0.score == top }?.id
        }
        let changed = newHolder != crownHolder && newHolder != nil
        crownHolder = newHolder
        return changed
    }

    // MARK: - Chrome

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // The bar stays in place during the celebration (removing it would shift the
        // layout); its contents and glass backgrounds just fade away.
        ToolbarItem(placement: .principal) {
            Text("What The Farkle")
                .font(.custom("Daydream", size: 16))
                .fontWeight(.bold)
                .opacity(isCelebrating ? 0 : 1)
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if !gameState.players.isEmpty {
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!gameState.canUndoLastScoreEntry || isBanking)
                .opacity(isCelebrating ? 0 : (gameState.canUndoLastScoreEntry && !isBanking ? 1.0 : 0.35))
                .accessibilityLabel("Undo")
            }
        }
        .sharedBackgroundVisibility(isCelebrating ? .hidden : .visible)

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if !gameState.players.isEmpty {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        Label("New game", systemImage: "arrow.counterclockwise")
                    }
                }
                Button(action: { showingRulesSheet = true }) {
                    Label("Farkle rules", systemImage: "book")
                }
                Toggle(isOn: $soundEnabled) {
                    Label("Sound", systemImage: soundEnabled ? "speaker.wave.2" : "speaker.slash")
                }
                #if DEBUG
                Button(action: { showingSoundLab = true }) {
                    Label("Sound lab", systemImage: "waveform")
                }
                #endif
            } label: {
                Image(systemName: "ellipsis.circle")
                    .opacity(isCelebrating ? 0 : 1)
            }
        }
        .sharedBackgroundVisibility(isCelebrating ? .hidden : .visible)
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if let winner = gameState.winner {
            CelebrationView(winnerName: winner.name, videoURL: gameVideoURL) {
                // Hide the backdrop before swapping in the next game's, so it can
                // build in fresh once the celebration slides away.
                isIntroRevealed = false
                showContent = false
                let selection = videoCache.selectForNewGame()
                gameVideoURL = selection.url
                gameImageName = selection.name
                showingCelebration = false
            }
        } else {
            Color.black.ignoresSafeArea()
        }
    }
}

// MARK: - Score flight

private struct ScoreFlight {
    let text: String
    let from: CGPoint
    let to: CGPoint
    var arrivedX = false
    var arrivedY = false
}

private struct ScoreFlightView: View {
    let flight: ScoreFlight

    var body: some View {
        Text(flight.text)
            .font(.custom("GeistMono-Regular", size: 34))
            .foregroundColor(Palette.accent)
            .shadow(color: Palette.accent.opacity(0.6), radius: flight.arrivedY ? 10 : 0)
            .scaleEffect(flight.arrivedY ? 0.6 : 1)
            .position(x: flight.arrivedX ? flight.to.x : flight.from.x,
                      y: flight.arrivedY ? flight.to.y : flight.from.y)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Frames measured during layout. A plain class on purpose: rows report their
/// frames on every scroll tick, and none of that should trigger a re-render.
private final class GameGeometry {
    var displayFrame: CGRect = .zero
    var scoreFrames: [UUID: CGRect] = [:]
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

// MARK: - Debug demo

#if DEBUG
/// Drives the game from a launch argument, for recording motion in the simulator
/// without tapping: `-demo bank`, `-demo farkle`, `-demo final`, `-demo win`.
private enum DemoScript {
    static func run(on view: ContentView) {
        guard let demo = UserDefaults.standard.string(forKey: "demo") else { return }
        func after(_ delay: Double, _ work: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
        switch demo {
        case "farkle":
            after(2.0) { view.farkle() }
            after(3.2) { view.farkle() }
        case "bank":
            after(2.0) { view.bank(1500) }
        case "final":
            after(2.0) { view.bank(4000) }
        case "win":
            after(2.0) { view.bank(4000) }
            after(3.6) { view.bank(9000) }
            after(5.2) { view.farkle() }
        default:
            break
        }
    }
}
#endif

#Preview {
    ContentView()
        .environment(GameState())
}
