import SwiftUI

struct ScoreInputView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var currentInput: String
    let onSubmit: (Int) -> Void
    let onFarkle: () -> Void
    private var score: Int { Int(currentInput) ?? 0 }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This turn").font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Arcade.muted)
                    Text(score.formatted())
                        .font(Arcade.mono(38)).foregroundStyle(Arcade.cream)
                        .contentTransition(.numericText(value: Double(score)))
                        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: score)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .accessibilityLabel("This turn: \(score) points")
                }
                Spacer()
                Button {
                    if !currentInput.isEmpty { currentInput.removeLast() }
                    ArcadeFeedback.shared.play(.tap)
                } label: {
                    Image(systemName: "delete.left").font(.title3)
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Delete last digit")
                .disabled(currentInput.isEmpty).opacity(currentInput.isEmpty ? 0.3 : 1)
            }
            .padding(.horizontal, 4)
            HStack(spacing: 8) {
                ForEach([50, 100, 500], id: \.self) { points in
                    Button {
                        currentInput = String(min(score + points, 999999))
                        ArcadeFeedback.shared.play(.tap)
                    } label: {
                        Text("+\(points)").font(Arcade.mono(14))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Arcade.mint.opacity(0.09), in: Capsule())
                    }
                    .buttonStyle(.plain).foregroundStyle(Arcade.mint)
                    .accessibilityLabel("Add \(points) points to this turn")
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3", "00", "0", "50"], id: \.self) { number in
                    CalculatorButton(title: number, foregroundColor: number.count == 2 ? Arcade.mint : Arcade.cream) {
                        guard currentInput.count + number.count <= 6 else { return }
                        currentInput = String(Int(currentInput + number) ?? 0)
                    }
                    .accessibilityLabel(number.count == 2 ? "Append \(number)" : number)
                }
            }
            HStack(spacing: 10) {
                Button {
                    currentInput = ""
                    onFarkle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark").font(.subheadline.bold())
                        Text("Farkle!").font(Arcade.display(12))
                    }
                }
                .buttonStyle(ArcadeButtonStyle(fill: Arcade.coral))
                .accessibilityHint("Score zero and pass the dice to the next player")
                Button { onSubmit(score) } label: {
                    HStack(spacing: 8) {
                        Text("Bank").font(Arcade.display(12))
                        Image(systemName: "arrow.down.to.line").font(.subheadline.bold())
                    }
                }
                .buttonStyle(ArcadeButtonStyle())
                .disabled(score <= 0).opacity(score <= 0 ? 0.4 : 1)
                .accessibilityHint("Save this turn’s points and pass the dice")
            }
            .padding(.top, 5)
        }
        .padding(16)
        .background(Arcade.forest.opacity(0.96), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Arcade.mint.opacity(0.14)))
        .foregroundStyle(Arcade.cream)
    }
}
