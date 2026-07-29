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
    @State private var currentInput = ""
    @State private var showingPlayerList = false
    @State private var showingResetAlert = false
    @State private var showingRulesSheet = false
    @State private var showingCelebration = false
    @State private var gameVideoURL: URL? = nil
    @State private var gameImageName: String? = nil
    @State private var isBanking = false
    @State private var introProgress: Double = 0
    @State private var showContent: Bool = false
    @State private var hasPlayedIntro: Bool = false
    
    var body: some View {
        Group {
            if gameState.players.isEmpty {
                StartGameView()
            } else {
                // Game view - with navigation
                NavigationStack {
                    gameInProgressView
                        .navigationTitle("What The Farkle")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            toolbarContent
                        }
                        .sheet(isPresented: $showingPlayerList) {
                            PlayerListView()
                        }
                        .sheet(isPresented: $showingRulesSheet) {
                            FarkleRulesView()
                        }
                        .alert("New game", isPresented: $showingResetAlert) {
                            Button("Cancel", role: .cancel) { }
                            Button("New game", role: .destructive) {
                                gameState.resetGame()
                                currentInput = ""
                            }
                        } message: {
                            Text("This will remove all players and reset the game. Are you sure?")
                        }
                        .onChange(of: gameState.winner) { _, newValue in
                            if newValue != nil {
                                showingCelebration = true
                            }
                        }
                        .fullScreenCover(isPresented: $showingCelebration, onDismiss: {
                            gameState.resetScores()
                        }) {
                            celebrationOverlay
                        }
                }
            }
        }
        .onChange(of: gameState.players.isEmpty) { _, isEmpty in
            if isEmpty {
                hasPlayedIntro = false
                introProgress = 0
                showContent = false
            }
        }
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
                                    isLast: index == gameState.players.count - 1
                                )
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
                        withAnimation(.easeInOut(duration: 0.3)) {
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

            ScoreInputView(currentInput: $currentInput) { score in
                guard !isBanking, let currentPlayer = gameState.currentPlayer else { return }
                isBanking = true
                gameState.applyBankedScore(score, to: currentPlayer.id)
                currentInput = ""
                // Let the progress bar animation play before the turn moves on
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        gameState.advanceTurn()
                    }
                    isBanking = false
                }
            } onFarkle: {
                guard !isBanking else { return }
                gameState.advanceTurn()
            }
            .opacity(showContent ? 1 : 0)
        }
        .background {
            ZStack {
                Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) // #1B2918
                if let name = gameImageName {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.18),
                                    .init(color: .black, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .scaleEffect(x: 1, y: introProgress, anchor: .bottom)
                        }
                    VerticalBuildEmitter(progress: introProgress)
                        .allowsHitTesting(false)
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
            if !hasPlayedIntro {
                hasPlayedIntro = true
                withAnimation(.easeOut(duration: 1.0)) {
                    introProgress = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showContent = true
                    }
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("What The Farkle")
                .font(.custom("Daydream", size: 16))
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarLeading) {
            if !gameState.players.isEmpty {
                Button(action: {
                    gameState.undoLastScoreEntry()
                    currentInput = ""
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!gameState.canUndoLastScoreEntry || isBanking)
                .opacity(gameState.canUndoLastScoreEntry && !isBanking ? 1.0 : 0.35)
            }
        }

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
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            if let winner = gameState.winner {
                CelebrationView(winnerName: winner.name, videoURL: gameVideoURL) {
                    let selection = videoCache.selectForNewGame()
                    gameVideoURL = selection.url
                    gameImageName = selection.name
                    showingCelebration = false
                }
            }
        }
    }
}

private struct VerticalBuildEmitter: View {
    let progress: Double

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
            system.beginSweep(from: oldValue, to: newValue)
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

    // Matches the intro reveal's .easeOut(duration: 1.0)
    private let sweepDuration: TimeInterval = 1.0

    private static let palette: [Color] = [
        Color(red: 233/255.0, green: 255/255.0, blue: 224/255.0), // #E9FFE0 very light
        Color(red: 185/255.0, green: 239/255.0, blue: 168/255.0), // #B9EFA8 light
        Color(red: 145/255.0, green: 218/255.0, blue: 127/255.0), // #91DA7F mid
        Color(red: 96/255.0, green: 191/255.0, blue: 72/255.0),   // #60BF48 dark
        Color(red: 60/255.0, green: 110/255.0, blue: 45/255.0),   // deep
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

        // Single dense line of particles riding the leading edge as it climbs
        let edgeCount = 80
        for i in 0..<edgeCount {
            let normalized = (CGFloat(i) + 0.5) / CGFloat(edgeCount)
            let x = margin + canvasWidth * normalized + .random(in: -5...5)
            particles.append(
                Particle(
                    x: x,
                    y: edgeY + .random(in: -6...2),
                    vx: .random(in: -6...6),
                    vy: .random(in: -10...4),
                    age: 0,
                    lifetime: .random(in: 0.15...0.28),
                    size: [4, 5, 5, 6, 6, 7].randomElement()!,
                    color: Self.palette.randomElement()!,
                    gravity: 0
                )
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}

