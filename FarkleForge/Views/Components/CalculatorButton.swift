//
//  CalculatorButton.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct CalculatorButton: View {
    let title: String
    let foregroundColor: Color
    let sound: SoundEffect
    let action: () -> Void

    @State private var isPressed = false
    /// Bumped on every press so the highlight flash replays even on rapid repeat taps.
    @State private var pressCount = 0

    init(
        title: String,
        foregroundColor: Color = .white, // #FFFFFF default
        sound: SoundEffect,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.sound = sound
        self.action = action
    }

    var body: some View {
        Text(title)
            .font(.custom("GeistMono-Regular", size: 34))
            .foregroundColor(isPressed ? Palette.accent : foregroundColor)
            .scaleEffect(isPressed ? 0.86 : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // Pill flash: snaps on at touch-down, then melts away.
                Capsule()
                    .fill(Palette.accent)
                    .keyframeAnimator(initialValue: 0.0, trigger: pressCount) { content, opacity in
                        content.opacity(opacity)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(0.2, duration: 0.03)
                            LinearKeyframe(0.2, duration: 0.06)
                            CubicKeyframe(0, duration: 0.35)
                        }
                    }
            }
            .contentShape(Rectangle())
            .frame(height: 60)
            // Fire on touch-down rather than release: score entry is fast, often
            // two-thumbed, and the sound should land the instant a finger does.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        withAnimation(.spring(response: 0.12, dampingFraction: 0.8)) {
                            isPressed = true
                        }
                        pressCount += 1
                        SoundEngine.shared.play(sound)
                        Haptics.tap()
                        action()
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                            isPressed = false
                        }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}

/// Squishes on press with a little spring back: used for the chunky pill buttons.
struct SquishButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(
                configuration.isPressed
                    ? .spring(response: 0.15, dampingFraction: 0.8)
                    : .spring(response: 0.35, dampingFraction: 0.5),
                value: configuration.isPressed
            )
    }
}

#Preview {
    CalculatorButton(title: "5", sound: .key(5)) {
        print("Button tapped")
    }
    .padding()
    .background(Palette.forest)
}
