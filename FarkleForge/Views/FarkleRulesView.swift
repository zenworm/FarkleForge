//
//  FarkleRulesView.swift
//  FarkleForge
//

import SwiftUI

private let accentGreen = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0)
private let sheetBg = Color(red: 0.10, green: 0.16, blue: 0.09)

struct FarkleRulesView: View {
    @Environment(\.dismiss) private var dismiss

    private let rules: [(name: String, dice: [Int], score: String)] = [
        ("Each one",       [1],             "100"),
        ("Each five",      [5],             "50"),
        ("Three ones",     [1, 1, 1],       "1000"),
        ("Three twos",     [2, 2, 2],       "200"),
        ("Three threes",   [3, 3, 3],       "300"),
        ("Three fours",    [4, 4, 4],       "400"),
        ("Three fives",    [5, 5, 5],       "500"),
        ("Three sixes",    [6, 6, 6],       "600"),
        ("Four of a kind", [5, 5, 5, 5],     "1000"),
        ("Five of a kind", [5, 5, 5, 5, 5],  "2000"),
        ("Six of a kind",  [6, 6, 6, 6, 6, 6], "3000"),
        ("Three pair",     [1, 1, 2, 2, 3, 3], "1500"),
        ("Run",            [1, 2, 3, 4, 5, 6], "2500"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(rules.enumerated()), id: \.offset) { idx, rule in
                        RuleRowView(
                            name: rule.name,
                            dice: rule.dice,
                            score: rule.score,
                            alternate: idx % 2 == 1
                        )
                        if idx < rules.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.08))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(sheetBg)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Farkle Rules")
                        .font(.custom("Daydream", size: 16))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(accentGreen)
                        .font(.custom("Daydream", size: 14))
                }
            }
            .toolbarBackground(sheetBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationBackground(sheetBg)
        .presentationDragIndicator(.visible)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Combination")
                .frame(width: 118, alignment: .leading)
            Spacer()
            Text("Dice")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Score")
                .frame(width: 50, alignment: .trailing)
        }
        .font(.custom("IowanOldStyle-Bold", size: 11))
        .foregroundColor(.white.opacity(0.45))
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.07))
    }
}

private struct RuleRowView: View {
    let name: String
    let dice: [Int]
    let score: String
    let alternate: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(name)
                .font(.custom("IowanOldStyle-Roman", size: 13))
                .foregroundColor(.white)
                .frame(width: 118, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            HStack(spacing: 3) {
                ForEach(Array(dice.enumerated()), id: \.offset) { _, face in
                    DieView(face: face, size: 24)
                }
            }

            Spacer(minLength: 6)

            Text(score)
                .font(.custom("IowanOldStyle-Bold", size: 14))
                .foregroundColor(accentGreen)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(alternate ? Color.white.opacity(0.03) : Color.clear)
    }
}

struct DieView: View {
    let face: Int
    var size: CGFloat = 30

    private func dotCenters(s: CGFloat) -> [CGPoint] {
        let p = s * 0.23
        let f = s - p
        let m = s * 0.5
        switch face {
        case 1: return [.init(x: m, y: m)]
        case 2: return [.init(x: f, y: p), .init(x: p, y: f)]
        case 3: return [.init(x: f, y: p), .init(x: m, y: m), .init(x: p, y: f)]
        case 4: return [.init(x: p, y: p), .init(x: f, y: p),
                        .init(x: p, y: f), .init(x: f, y: f)]
        case 5: return [.init(x: p, y: p), .init(x: f, y: p),
                        .init(x: m, y: m),
                        .init(x: p, y: f), .init(x: f, y: f)]
        case 6: return [.init(x: p, y: p), .init(x: f, y: p),
                        .init(x: p, y: m), .init(x: f, y: m),
                        .init(x: p, y: f), .init(x: f, y: f)]
        default: return []
        }
    }

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width
            let corner = s * 0.18
            let dotR = s * 0.11
            let strokeW = s * 0.055

            let bgRect = CGRect(origin: .zero, size: canvasSize)
            let bgPath = Path(roundedRect: bgRect, cornerRadius: corner)
            ctx.fill(bgPath, with: .color(.white))
            ctx.stroke(bgPath, with: .color(.black), lineWidth: strokeW)

            for pt in dotCenters(s: s) {
                let r = CGRect(x: pt.x - dotR, y: pt.y - dotR, width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: r), with: .color(.black))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    FarkleRulesView()
}
