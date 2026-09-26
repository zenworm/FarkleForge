//
//  ScoreInputView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct ScoreInputView: View {
    @Binding var currentInput: String
    /// Hidden while the banked number is flying up to the player's row.
    var isDisplayHidden: Bool = false
    let onSubmit: (Int) -> Void
    let onFarkle: () -> Void
    /// Reports the display's frame (in the "game" coordinate space) so the banked
    /// number can take off from exactly where it was typed.
    var onDisplayFrame: (CGRect) -> Void = { _ in }

    @State private var nopeCount = 0

    private let farkleTint = Palette.farkle
    private let accentGreen = Palette.accent
    private let bankGreen = Palette.leaf // matches active player background
    private let bankTextColor = Palette.ink // matches active player text
    private let maxLength = 6

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Display current input
            ZStack {
                // Each digit pops in on its own spring as it's typed
                HStack(spacing: 0) {
                    ForEach(Array(currentInput.enumerated()), id: \.offset) { _, character in
                        Text(String(character))
                            .transition(.digit)
                    }
                }
                .font(.custom("GeistMono-Regular", size: 34))
                .foregroundColor(accentGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .opacity(isDisplayHidden ? 0 : 1)
                .keyframeAnimator(initialValue: 0.0, trigger: nopeCount) { content, x in
                    content.offset(x: x)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(8, duration: 0.04)
                        LinearKeyframe(-7, duration: 0.05)
                        LinearKeyframe(4, duration: 0.05)
                        SpringKeyframe(0, duration: 0.12)
                    }
                }
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named("game"))
                } action: { frame in
                    onDisplayFrame(frame)
                }
                .padding(.horizontal, 60) // keep clear of the reset button

                // Reset button pinned to the left (only shown when there's input)
                if !currentInput.isEmpty && !isDisplayHidden {
                    HStack {
                        Button(action: clear) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(SquishButtonStyle(scale: 0.8))
                        .accessibilityLabel("Clear")
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 72)
            .padding(.horizontal)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentInput.isEmpty)

            // Number pad
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3"], id: \.self) { number in
                    CalculatorButton(title: number, sound: .key(Int(number)!)) {
                        appendNumber(number)
                    }
                }

                CalculatorButton(
                    title: "00",
                    foregroundColor: accentGreen,
                    sound: .keyPair("00")
                ) {
                    appendShortcut("00")
                }

                CalculatorButton(title: "0", sound: .key(0)) {
                    appendNumber("0")
                }

                CalculatorButton(
                    title: "50",
                    foregroundColor: accentGreen,
                    sound: .keyPair("50")
                ) {
                    appendShortcut("50")
                }
            }
            .padding(.horizontal)

            // Action bar: two fully rounded pill buttons on a single row
            HStack(spacing: 12) {
                Button(action: farkle) {
                    Text("Farkle")
                        .font(.custom("Daydream", size: 12))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(farkleTint, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(SquishButtonStyle())

                Button(action: submitScore) {
                    Text("Bank")
                        .font(.custom("Daydream", size: 12))
                        .foregroundStyle(bankTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(bankGreen, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(SquishButtonStyle())
                .opacity(currentInput.isEmpty ? 0.4 : 1.0)
                .disabled(currentInput.isEmpty)
                // A little "ready!" hop the moment there's something to bank
                .keyframeAnimator(initialValue: 1.0, trigger: currentInput.isEmpty) { [isEmpty = currentInput.isEmpty] content, scale in
                    content.scaleEffect(isEmpty ? 1 : scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(1.06, duration: 0.12)
                        SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: currentInput.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func appendNumber(_ number: String) {
        // Limit input length
        guard currentInput.count < maxLength else { return refuse() }
        // A leading zero is never a score; ignore it rather than show "0"
        guard !(currentInput.isEmpty && number == "0") else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
            currentInput += number
        }
    }

    private func clear() {
        SoundEngine.shared.play(.clear)
        Haptics.soft(0.5)
        withAnimation(.easeIn(duration: 0.18)) {
            currentInput = ""
        }
    }

    private func appendShortcut(_ shortcut: String) {
        // Limit total input length
        guard currentInput.count + shortcut.count <= maxLength else { return refuse() }
        guard !currentInput.isEmpty || shortcut != "00" else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
            currentInput += shortcut
        }
    }

    private func refuse() {
        nopeCount += 1
        SoundEngine.shared.play(.nope)
        Haptics.warning()
    }

    private func submitScore() {
        if let score = Int(currentInput) {
            onSubmit(score)
        }
    }

    private func farkle() {
        onFarkle()
    }
}

private extension AnyTransition {
    /// Digits spring up into place when typed and drop away when cleared.
    static var digit: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.4, anchor: .bottom)
                .combined(with: .offset(y: 10))
                .combined(with: .opacity),
            removal: .offset(y: 28).combined(with: .opacity)
        )
    }
}

#Preview {
    ScoreInputView(currentInput: .constant("1500")) { score in
        print("Score submitted: \(score)")
    } onFarkle: {
        print("Farkle!")
    }
    .background(Palette.forest)
}
