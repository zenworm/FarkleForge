//
//  GameMoments.swift
//  FarkleForge
//
//  The overlays for the game's big beats: the red edge flash when someone farkles,
//  and the tilted sticker that carries the joke (or announces the final round).
//  Both are non-interactive so they never get in the way of the next turn.
//

import SwiftUI

struct GameSticker: Equatable, Identifiable {
    enum Style { case farkle, finalRound }

    let id = UUID()
    let style: Style
    let title: String
    let message: String
    /// Alternates the tilt so consecutive stickers don't look stamped from the same die.
    let tilt: Double
}

/// A sticker slapped onto the screen: overshoots in, sits for a beat, then drops away.
struct StickerView: View {
    let sticker: GameSticker

    private var background: Color {
        sticker.style == .farkle ? Palette.farkle : Palette.gold
    }

    private var foreground: Color {
        sticker.style == .farkle ? .white : Palette.ink
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if sticker.style == .finalRound {
                    PixelCrown(pixel: 2, tint: Palette.ink)
                }
                Text(sticker.title)
                    .font(.custom("Daydream", size: 13))
                    .tracking(1)
            }
            .opacity(0.85)

            Text(sticker.message)
                .font(.custom("JetBrainsMono-Medium", size: 19))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: 300)
        .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        .rotationEffect(.degrees(sticker.tilt))
        .accessibilityElement(children: .combine)
    }
}

extension AnyTransition {
    static var sticker: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 1.5).combined(with: .opacity),
            removal: .scale(scale: 0.85).combined(with: .opacity).combined(with: .offset(y: 24))
        )
    }
}

/// Red light bleeding in from the screen edges. Flashes in fast, fades out slower.
struct FarkleVignette: View {
    let trigger: Int

    var body: some View {
        Rectangle()
            .fill(
                EllipticalGradient(
                    colors: [.clear, Palette.farkle.opacity(0.18), Palette.farkle.opacity(0.7)],
                    center: .center,
                    startRadiusFraction: 0.5,
                    endRadiusFraction: 0.82
                )
            )
            .overlay {
                // A tighter glow hugging the device corners.
                RoundedRectangle(cornerRadius: 56, style: .continuous)
                    .strokeBorder(Palette.farkle, lineWidth: 18)
                    .blur(radius: 18)
            }
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, opacity in
                content.opacity(opacity)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(1.0, duration: 0.06)
                    LinearKeyframe(1.0, duration: 0.18)
                    CubicKeyframe(0.0, duration: 0.6)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

extension View {
    /// A very quick, damped rattle. Over in about a third of a second.
    func farkleShake(trigger: Int, enabled: Bool) -> some View {
        keyframeAnimator(initialValue: ShakeValue(), trigger: trigger) { content, value in
            content
                .offset(x: enabled ? value.x : 0)
                .rotationEffect(.degrees(enabled ? value.angle : 0))
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                LinearKeyframe(-14, duration: 0.04)
                LinearKeyframe(12, duration: 0.05)
                LinearKeyframe(-9, duration: 0.05)
                LinearKeyframe(6, duration: 0.05)
                LinearKeyframe(-3, duration: 0.05)
                SpringKeyframe(0, duration: 0.12)
            }
            KeyframeTrack(\.angle) {
                LinearKeyframe(-1.2, duration: 0.05)
                LinearKeyframe(0.9, duration: 0.07)
                LinearKeyframe(-0.4, duration: 0.07)
                SpringKeyframe(0, duration: 0.15)
            }
        }
    }
}

/// The foggy game background. The leader's progress is the whole game's progress
/// bar: as `closeness` rises the camera leans in toward the animal hiding in the
/// fog and a soft light finds it. The celebration is presented over this same
/// view, so the animal builds up out of the exact frame the game ended on.
struct FogBackdrop: View {
    let imageName: String
    /// 0 at the start of a game, 1 once someone has reached the target.
    let closeness: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var focus: UnitPoint {
        AnimalCatalog.animal(forBackground: imageName)?.focus ?? UnitPoint(x: 0.5, y: 0.25)
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .overlay {
                RadialGradient(
                    colors: [Palette.mist.opacity(0.55 * closeness), .clear],
                    center: focus,
                    startRadius: 0,
                    endRadius: 240
                )
                .blendMode(.softLight)
            }
            .scaleEffect(reduceMotion ? 1 : 1 + 0.16 * closeness, anchor: focus)
    }
}

struct ShakeValue {
    var x: CGFloat = 0
    var angle: Double = 0
}

#Preview {
    ZStack {
        Palette.forest.ignoresSafeArea()
        VStack(spacing: 60) {
            StickerView(sticker: GameSticker(style: .farkle, title: "Farkle!", message: "Thoughts and prayers, Roger.", tilt: -3))
            StickerView(sticker: GameSticker(style: .finalRound, title: "Final round", message: "Beat Mary's 10,250", tilt: 2))
        }
    }
}
