import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.videoCache) private var videoCache
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentInput = ""
    @State private var showingResetAlert = false
    @State private var showingRules = false
    @State private var showingCelebration = false
    @State private var gameVideoURL: URL?
    @State private var gameImageName: String?
    @State private var isBanking = false
    @State private var feedback: String?
    @State private var busted = false
    @State private var turnTask: Task<Void, Never>?
    @State private var burst = 0

    var body: some View {
        Group {
            if gameState.players.isEmpty {
                StartGameView()
            } else {
                gameTable
            }
        }
        .tint(Arcade.mint)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingRules) { FarkleRulesView() }
        .alert("Leave this table?", isPresented: $showingResetAlert) {
            Button("Keep playing", role: .cancel) { }
            Button("New game", role: .destructive) {
                turnTask?.cancel()
                gameState.resetGame()
                currentInput = ""
                gameImageName = nil
                gameVideoURL = nil
                feedback = nil
            }
        } message: {
            Text("This clears the scores so you can set up a new game.")
        }
        .onChange(of: gameState.winner) { _, winner in
            if winner != nil {
                ArcadeFeedback.shared.play(.win)
                showingCelebration = true
            }
        }
        .fullScreenCover(isPresented: $showingCelebration) {
            if let winner = gameState.winner {
                CelebrationView(winnerName: winner.name, videoURL: gameVideoURL) {
                    showingCelebration = false
                    gameState.resetScores()
                    currentInput = ""
                    feedback = nil
                    selectLandscape()
                }
                .interactiveDismissDisabled()
            }
        }
        .onDisappear {
            // Finish a committed turn if navigation removes the view during feedback.
            turnTask?.cancel()
            if isBanking { gameState.advanceTurn(); isBanking = false }
        }
    }

    private var gameTable: some View {
        GeometryReader { geometry in
            if dynamicTypeSize >= .xxLarge || geometry.size.height < 650 {
                ScrollView { tableContents(rosterHeight: 220) }
            } else {
                tableContents(rosterHeight: nil)
            }
        }
        .background(ArcadeBackground(image: gameImageName ?? "startBg"))
        .onAppear { if gameImageName == nil { selectLandscape() } }
    }

    private func tableContents(rosterHeight: CGFloat?) -> some View {
        VStack(spacing: 14) {
            header
            HStack {
                Label(gameState.isFinalRound ? "Final round!" : "Race to \(gameState.targetScore.formatted())", systemImage: gameState.isFinalRound ? "flame.fill" : "flag.checkered")
                    .foregroundStyle(gameState.isFinalRound ? Arcade.gold : Arcade.muted)
                Spacer()
                Label("\(gameState.players.count) players", systemImage: "arrow.up.arrow.down").foregroundStyle(Arcade.muted)
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .padding(.horizontal, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                            PlayerRowView(player: player,
                                          isCurrentTurn: player.id == gameState.currentPlayer?.id,
                                          isFinalRound: gameState.isFinalRound,
                                          leaderScore: gameState.leaderScore,
                                          targetScore: gameState.targetScore,
                                          isFirst: index == 0,
                                          isLast: index == gameState.players.count - 1,
                                          seat: index)
                            .id(player.id)
                        }
                    }
                    .padding(1)
                }
                .scrollIndicators(.hidden)
                .onChange(of: gameState.currentTurnIndex) { _, _ in
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) {
                        proxy.scrollTo(gameState.currentPlayer?.id, anchor: .top)
                    }
                }
            }
            .frame(height: rosterHeight)
            .frame(maxHeight: rosterHeight == nil ? .infinity : nil)

            HStack(spacing: 8) {
                Image(systemName: feedback == nil ? "die.face.5.fill" : busted ? "cloud.bolt.fill" : "checkmark.seal.fill")
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : burst)
                Text(feedback ?? "\(gameState.currentPlayer?.name ?? "")’s turn")
                    .lineLimit(2)
                    .contentTransition(.opacity)
                Spacer(minLength: 0)
                if feedback == nil {
                    Text("Roll → enter → bank")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Arcade.muted)
                }
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(feedback != nil && busted ? Arcade.coral : Arcade.mint)
            .frame(minHeight: 28)
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.updatesFrequently)

            ScoreInputView(currentInput: $currentInput) { points in
                commitTurn(points: points)
            } onFarkle: {
                commitTurn(points: 0)
            }
            .disabled(isBanking || gameState.winner != nil)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18).padding(.top, 6).padding(.bottom, 12)
        .frame(maxWidth: 560).frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                gameState.undoLastScoreEntry()
                currentInput = ""
                feedback = nil
                ArcadeFeedback.shared.play(.tap)
            } label: {
                Image(systemName: "arrow.uturn.backward").font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.06), in: Circle())
            }
            .accessibilityLabel("Undo last turn")
            .disabled(!gameState.canUndoLastScoreEntry || isBanking)
            .opacity(gameState.canUndoLastScoreEntry && !isBanking ? 1 : 0.3)
            Spacer(minLength: 0)
            VStack(spacing: 2) {
                Text("WHAT THE").font(Arcade.display(9))
                Text("FARKLE").font(Arcade.display(18)).foregroundStyle(Arcade.mint)
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("What The Farkle")
            Spacer(minLength: 0)
            SoundButton()
            Menu {
                Button { showingRules = true } label: { Label("Scoring guide", systemImage: "book") }
                Button(role: .destructive) { showingResetAlert = true } label: { Label("New game", systemImage: "arrow.counterclockwise") }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44).background(.white.opacity(0.06), in: Circle())
            }
            .accessibilityLabel("Game options").disabled(isBanking)
        }
        .buttonStyle(.plain).foregroundStyle(Arcade.cream)
    }

    private func selectLandscape() {
        let selection = videoCache.selectForNewGame()
        gameVideoURL = selection.url
        gameImageName = selection.name
    }

    private func commitTurn(points: Int) {
        guard !isBanking, gameState.winner == nil, let player = gameState.currentPlayer else { return }
        turnTask?.cancel()
        isBanking = true
        busted = points == 0
        gameState.applyBankedScore(points, to: player.id)
        currentInput = ""
        withAnimation(reduceMotion ? nil : .snappy) {
            feedback = points == 0 ? "Farkle! Shake it off, \(player.name)." : "+\(points.formatted()) banked. Nice one, \(player.name)!"
            burst += 1
        }
        ArcadeFeedback.shared.play(points == 0 ? .farkle : .bank)
        UIAccessibility.post(notification: .announcement, argument: feedback)
        turnTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 650))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) { gameState.advanceTurn() }
            isBanking = false
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut) { feedback = nil }
        }
    }
}

#Preview { ContentView().environment(GameState()) }
