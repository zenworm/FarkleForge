import SwiftUI

struct StartGameView: View {
    @Environment(GameState.self) private var gameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var names = ["Mary", "Roger", "Iris", "Felix", "Daisy", "Otis", "Pippa", "Eli"]
    @State private var playerCount = 2
    @State private var target = 10000
    @State private var showingRules = false
    @FocusState private var focusedPlayer: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Good times. Bad rolls.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Arcade.muted)
                    Spacer()
                    SoundButton()
                    Button { showingRules = true } label: {
                        Image(systemName: "questionmark").font(.headline)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.06), in: Circle())
                    }
                    .accessibilityLabel("How to play Farkle")
                }
                VStack(spacing: 2) {
                    Text("WHAT THE").font(Arcade.display(22)).foregroundStyle(Arcade.cream)
                    Text("FARKLE").font(Arcade.display(43)).foregroundStyle(Arcade.mint)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.4), radius: 0, y: 5)
                    DiceTable()
                    Text("You bring the dice. We’ll keep score.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Arcade.cream)
                }
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Who’s at the table?").font(.system(.title3, design: .rounded, weight: .bold))
                        Spacer()
                        countButton("minus", disabled: playerCount == 2) { playerCount -= 1 }
                        Text("\(playerCount)").font(Arcade.mono(18)).contentTransition(.numericText())
                        countButton("plus", disabled: playerCount == 8) { playerCount += 1 }
                    }
                    VStack(spacing: 10) {
                        ForEach(0..<playerCount, id: \.self) { index in
                            HStack(spacing: 12) {
                                ArcadeDie(face: index % 6 + 1, size: 28, color: Arcade.playerColors[index])
                                TextField("Player \(index + 1)", text: $names[index])
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .focused($focusedPlayer, equals: index)
                                    .autocorrectionDisabled().textInputAutocapitalization(.words)
                                    .submitLabel(index == playerCount - 1 ? .done : .next)
                                    .onSubmit { focusedPlayer = index == playerCount - 1 ? nil : index + 1 }
                                    .accessibilityLabel("Player \(index + 1) name")
                                if index == 0 {
                                    Text("First up").font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(Arcade.muted)
                                }
                            }
                            .padding(13)
                            .background(Arcade.forest.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    Text("Race to").font(.system(.subheadline, design: .rounded, weight: .semibold))
                    HStack(spacing: 8) {
                        ForEach([2500, 5000, 10000], id: \.self) { value in
                            Button {
                                target = value
                                ArcadeFeedback.shared.play(.tap)
                            } label: {
                                VStack(spacing: 5) {
                                    Text(value.formatted()).font(Arcade.mono(16)).lineLimit(1).minimumScaleFactor(0.6)
                                    Text(value == 2500 ? "Quick" : value == 5000 ? "Casual" : "Classic")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .foregroundStyle(target == value ? Arcade.forest : Arcade.cream)
                                .background(target == value ? Arcade.mint : Arcade.forest, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(target == value ? .isSelected : [])
                        }
                    }
                }
                .padding(18)
                .background(Arcade.panel.opacity(0.9), in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Arcade.mint.opacity(0.12)))
                Text("Real dice. Real friends. Questionable luck.")
                    .font(.system(.caption, design: .rounded)).foregroundStyle(Arcade.muted)
            }
            .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(action: startGame) {
                HStack {
                    Text("Let’s Farkle").font(Arcade.display(16))
                    Spacer()
                    Image(systemName: "arrow.right").font(.title3.bold())
                }
            }
            .buttonStyle(ArcadeButtonStyle())
            .disabled(!canStart).opacity(canStart ? 1 : 0.45)
            .padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 12)
            .background(Arcade.forest.opacity(0.95))
        }
        .foregroundStyle(Arcade.cream)
        .background(ArcadeBackground())
        .sheet(isPresented: $showingRules) { FarkleRulesView() }
    }

    private var canStart: Bool {
        names.prefix(playerCount).allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func countButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            focusedPlayer = nil
            withAnimation(reduceMotion ? nil : .snappy) { action() }
            ArcadeFeedback.shared.play(.tap)
        } label: {
            Image(systemName: icon).font(.system(size: 13, weight: .bold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain).disabled(disabled).opacity(disabled ? 0.3 : 1)
        .accessibilityLabel(icon == "plus" ? "Add player" : "Remove player")
    }

    private func startGame() {
        focusedPlayer = nil
        gameState.targetScore = target
        for name in names.prefix(playerCount) {
            gameState.addPlayer(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        ArcadeFeedback.shared.play(.roll)
    }
}

#Preview { StartGameView().environment(GameState()) }
