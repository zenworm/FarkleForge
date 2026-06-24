//
//  StartGameView.swift
//  FarkleForge
//
//  Created on 2026-06-23.
//

import SwiftUI

struct StartGameView: View {
    @Environment(GameState.self) private var gameState

    @State private var playerCount: Int = 2
    @State private var names: [String] = StartGameView.defaultNames
    @State private var localTargetScore: Int = 10000
    @State private var showingScoreSheet = false
    @State private var showingPlayerCountSheet = false
    @FocusState private var focusedNameIndex: Int?
    @State private var nameBeforeEditing: String? = nil
    @State private var customizedNames: Set<Int> = []

    static let defaultNames = ["Mary", "Roger", "Iris", "Felix", "Daisy", "Otis", "Pippa", "Eli"]

    private static let backgroundColor = Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) // #1B2918
    private static let accentGreen = Color(red: 163/255.0, green: 234/255.0, blue: 146/255.0) // #A3EA92
    private static let bodyFont = Font.custom("JetBrainsMono-Medium", size: 22)

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 28) {
                Image("wtf")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .padding(.top, 40)

                paragraph
                    .padding(.horizontal)

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                startBar
            }
        }
        .background {
            Image("startBg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedNameIndex = nil
        }
        .sheet(isPresented: $showingScoreSheet) {
            scoreSheet
        }
        .sheet(isPresented: $showingPlayerCountSheet) {
            playerCountSheet
        }
        .onChange(of: focusedNameIndex) { oldValue, newValue in
            handleFocusChange(from: oldValue, to: newValue)
        }
    }

    private func handleFocusChange(from oldValue: Int?, to newValue: Int?) {
        if let old = oldValue, old != newValue, names.indices.contains(old) {
            let trimmed = names[old].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty, let saved = nameBeforeEditing {
                names[old] = saved
            } else if let saved = nameBeforeEditing, names[old] != saved {
                customizedNames.insert(old)
            }
        }
        if let new = newValue, new != oldValue, names.indices.contains(new) {
            nameBeforeEditing = names[new]
            if !customizedNames.contains(new) {
                names[new] = ""
            }
        } else if newValue == nil {
            nameBeforeEditing = nil
        }
    }

    private var paragraph: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("I want to play to")
                tappable(text: scoreString) { showingScoreSheet = true }
            }
            HStack(spacing: 8) {
                Text("with")
                tappable(text: "\(playerCount) players") { showingPlayerCountSheet = true }
            }
            FlowLayout(spacing: 6, lineSpacing: 8) {
                Text("named")
                ForEach(0..<playerCount, id: \.self) { i in
                    namedUnit(at: i)
                }
            }
        }
        .font(Self.bodyFont)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func namedUnit(at index: Int) -> some View {
        HStack(spacing: 6) {
            if index == playerCount - 1 && playerCount > 1 {
                Text("and")
            }
            nameSpan(at: index)
            if index < playerCount - 1 && playerCount > 2 {
                Text(",")
            }
        }
    }

    private func nameSpan(at index: Int) -> some View {
        TextField("Name", text: binding(for: index))
            .focused($focusedNameIndex, equals: index)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(Self.accentGreen)
            .underline()
            .tint(Self.accentGreen)
            .submitLabel(.done)
            .onSubmit { focusedNameIndex = nil }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
    }

    private func tappable(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(Self.accentGreen)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { names.indices.contains(index) ? names[index] : "" },
            set: { newValue in
                if names.indices.contains(index) { names[index] = newValue }
            }
        )
    }

    private var scoreString: String {
        StartGameView.scoreLabel(for: localTargetScore)
    }

    private static func scoreLabel(for score: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }

    private var startBar: some View {
        Button(action: startGame) {
            Text("Start game")
                .font(.custom("Daydream", size: 16))
                .foregroundStyle(canStart ? Self.accentGreen : Color.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
        .frame(height: 72)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial).opacity(0.5)
                VStack(spacing: 0) {
                    Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var canStart: Bool {
        (0..<playerCount).allSatisfy { i in
            i < names.count && !names[i].trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func startGame() {
        focusedNameIndex = nil
        gameState.targetScore = localTargetScore
        for i in 0..<playerCount {
            let trimmed = names[i].trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                gameState.addPlayer(name: trimmed)
            }
        }
    }

    private var scoreSheet: some View {
        VStack(spacing: 0) {
            ForEach([2500, 5000, 10000], id: \.self) { score in
                Button {
                    localTargetScore = score
                    showingScoreSheet = false
                } label: {
                    HStack {
                        Text(StartGameView.scoreLabel(for: score))
                            .font(.custom("GeistMono-Regular", size: 24))
                            .foregroundStyle(.white)
                        Spacer()
                        if score == localTargetScore {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Self.accentGreen)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if score != 10000 {
                    Divider().opacity(0.3)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .presentationDetents([.fraction(0.35)])
        .presentationBackground(Self.backgroundColor)
    }

    private var playerCountSheet: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        return VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(2...8, id: \.self) { count in
                    Button {
                        playerCount = count
                        showingPlayerCountSheet = false
                    } label: {
                        Text("\(count)")
                            .font(.custom("GeistMono-Bold", size: 24))
                            .foregroundStyle(playerCount == count ? Color.black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(playerCount == count ? Self.accentGreen : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .presentationDetents([.fraction(0.35)])
        .presentationBackground(Self.backgroundColor)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let arrangement = arrange(subviews: subviews, in: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? arrangement.maxX, height: arrangement.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, in: bounds.width)
        for placement in arrangement.placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.x, y: bounds.minY + placement.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: placement.size.width, height: placement.size.height)
            )
        }
    }

    private struct Placement {
        let index: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }

    private struct Arrangement {
        var placements: [Placement] = []
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
    }

    private func arrange(subviews: Subviews, in maxWidth: CGFloat) -> Arrangement {
        var arrangement = Arrangement()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            arrangement.placements.append(Placement(index: index, x: x, y: y, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            arrangement.maxX = max(arrangement.maxX, x - spacing)
        }
        arrangement.maxY = y + rowHeight
        return arrangement
    }
}

#Preview {
    StartGameView()
        .environment(GameState())
}
