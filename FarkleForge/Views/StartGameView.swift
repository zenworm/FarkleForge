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
    private static let startGreen = Color(red: 96/255.0, green: 191/255.0, blue: 72/255.0) // #60BF48 — matches active player / Bank button
    private static let startTextColor = Color(red: 22/255.0, green: 34/255.0, blue: 19/255.0) // #162213 — matches active player text
    /// The paragraph text scales with the viewport width: 22pt is the reference
    /// size on a 393pt-wide screen (iPhone 14/15), and it grows/shrinks from there.
    private func bodyFont(width: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: 22 * width / 393)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                VStack(spacing: 28) {
                    Image("wtf")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                        .padding(.top, 40)

                    paragraph(width: geo.size.width)
                        .padding(.horizontal)
                        .padding(.top, 24)

                    Spacer(minLength: 0)
                }

                VStack {
                    Spacer()
                    startBar
                }
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

    private func paragraph(width: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 10) {
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
        .font(bodyFont(width: width))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .center)
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
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
    }

    private func tappable(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(Self.accentGreen)
                .underline()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { names.indices.contains(index) ? names[index] : "" },
            set: { newValue in
                if names.indices.contains(index) { names[index] = Self.sanitizeName(newValue) }
            }
        )
    }

    /// Removes the stray whitespace iOS autocorrect can inject when it commits a
    /// suggestion: drops any leading spaces and collapses runs of whitespace to a
    /// single space. A single internal or trailing space is preserved so multi-word
    /// names still work; trailing space is trimmed when the game starts.
    private static func sanitizeName(_ raw: String) -> String {
        var result = ""
        var lastWasSpace = false
        for character in raw {
            if character == " " {
                // Skip a leading space or a second consecutive space.
                if result.isEmpty || lastWasSpace { continue }
                lastWasSpace = true
                result.append(character)
            } else {
                lastWasSpace = false
                result.append(character)
            }
        }
        return result
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
                .foregroundStyle(Self.startTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Capsule())
        }
        .background(Self.startGreen, in: Capsule())
        .buttonStyle(.plain)
        .opacity(canStart ? 1.0 : 0.4)
        .disabled(!canStart)
        .padding(.horizontal)
        .padding(.bottom, 8)
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
        VStack(spacing: 12) {
            ForEach([10000, 5000, 2500], id: \.self) { score in
                Button {
                    localTargetScore = score
                    showingScoreSheet = false
                } label: {
                    Text(StartGameView.scoreLabel(for: score))
                        .font(.custom("GeistMono-Bold", size: 24))
                        .foregroundStyle(localTargetScore == score ? Color.black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(localTargetScore == score ? Self.accentGreen : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
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
        var x: CGFloat
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
        var rowStart = 0 // index into placements where the current row begins

        // Centers the placements of the just-completed row within maxWidth.
        func centerRow(upTo end: Int, rowWidth: CGFloat) {
            guard maxWidth.isFinite else { return }
            let offset = max(0, (maxWidth - rowWidth) / 2)
            guard offset > 0 else { return }
            for i in rowStart..<end {
                arrangement.placements[i].x += offset
            }
        }

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                centerRow(upTo: arrangement.placements.count, rowWidth: x - spacing)
                rowStart = arrangement.placements.count
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            arrangement.placements.append(Placement(index: index, x: x, y: y, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            arrangement.maxX = max(arrangement.maxX, x - spacing)
        }
        centerRow(upTo: arrangement.placements.count, rowWidth: x - spacing)
        arrangement.maxY = y + rowHeight
        return arrangement
    }
}

#Preview {
    StartGameView()
        .environment(GameState())
}
