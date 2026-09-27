//
//  PixelCrown.swift
//  FarkleForge
//
//  Every animal wears a crown, so the crown is the game's prize: it sits on the
//  current leader's row, hints at undiscovered animals, and rains down at the end.
//

import SwiftUI

struct PixelCrown: View {
    /// Size of one "pixel" in points; the crown is 9 × 6 pixels.
    var pixel: CGFloat = 2
    /// Draws a single flat color instead of gold, for silhouettes.
    var tint: Color? = nil

    static let columns = 9
    static let rows = 6

    // g = gold, s = shadow gold, r = ruby, . = empty
    private static let map = [
        "g...g...g",
        "gg.ggg.gg",
        "ggggggggg",
        "ggrgggrgg",
        "ggggggggg",
        "sssssssss",
    ]

    var body: some View {
        Canvas { context, _ in
            Self.draw(in: &context, origin: .zero, pixel: pixel, tint: tint)
        }
        .frame(width: CGFloat(Self.columns) * pixel, height: CGFloat(Self.rows) * pixel)
        .accessibilityHidden(true)
    }

    /// Shared with Canvas-based views (the start screen bubbles draw crowns directly).
    static func draw(in context: inout GraphicsContext, origin: CGPoint, pixel: CGFloat, tint: Color? = nil, opacity: Double = 1) {
        for (y, row) in map.enumerated() {
            for (x, cell) in row.enumerated() where cell != "." {
                let color: Color
                if let tint {
                    color = tint
                } else {
                    switch cell {
                    case "s": color = Palette.goldShadow
                    case "r": color = Palette.ruby
                    default: color = Palette.gold
                    }
                }
                // Slight overlap hides hairline seams between pixels.
                let rect = CGRect(x: origin.x + CGFloat(x) * pixel, y: origin.y + CGFloat(y) * pixel,
                                  width: pixel + 0.5, height: pixel + 0.5)
                context.fill(Path(rect), with: .color(color.opacity(opacity)))
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        PixelCrown(pixel: 2)
        PixelCrown(pixel: 6)
        PixelCrown(pixel: 6, tint: Palette.accent.opacity(0.5))
    }
    .padding()
    .background(Palette.forest)
}
