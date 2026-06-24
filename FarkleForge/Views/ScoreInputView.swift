//
//  ScoreInputView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct ScoreInputView: View {
    @Binding var currentInput: String
    let onSubmit: (Int) -> Void
    let onFarkle: () -> Void
    
    private let farkleTint = Color(red: 255/255.0, green: 69/255.0, blue: 69/255.0) // #FF4545
    private let accentGreen = Color(red: 163/255.0, green: 234/255.0, blue: 146/255.0) // #A3EA92
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Display current input
            ZStack {
                // Numbers centered
                Text(currentInput.isEmpty ? "" : currentInput)
                    .font(.custom("GeistMono-Regular", size: 34))
                    .foregroundColor(accentGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 60) // keep clear of the reset button

                // Reset button pinned to the left (only shown when there's input)
                if !currentInput.isEmpty {
                    HStack {
                        Button(action: clear) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
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
                    CalculatorButton(
                        title: number,
                    ) {
                        appendNumber(number)
                    }
                }

                CalculatorButton(
                    title: "00",
                    foregroundColor: accentGreen
                ) {
                    appendShortcut("00")
                }

                CalculatorButton(
                    title: "0",
                ) {
                    appendNumber("0")
                }

                CalculatorButton(
                    title: "50",
                    foregroundColor: accentGreen
                ) {
                    appendShortcut("50")
                }
            }
            .padding(.horizontal)

            // Action bar: full-width glass extending under the bottom safe area
            HStack(spacing: 0) {
                Button(action: farkle) {
                    Text("Farkle")
                        .fontWeight(.semibold)
                        .foregroundStyle(farkleTint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: submitScore) {
                    Text("Bank")
                        .fontWeight(.semibold)
                        .foregroundStyle(currentInput.isEmpty ? Color.secondary : accentGreen)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(currentInput.isEmpty)
            }
            .frame(height: 72)
            .background {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.black.opacity(0.4)).frame(width: 1)
                        Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                        Spacer(minLength: 0)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.top, 8)
        }
    }
    
    private func appendNumber(_ number: String) {
        // Limit input length
        if currentInput.count < 6 {
            currentInput += number
        }
    }
    
    private func clear() {
        currentInput = ""
    }
    
    private func appendShortcut(_ shortcut: String) {
        // Limit total input length
        if currentInput.count + shortcut.count <= 6 {
            currentInput += shortcut
        }
    }
    
    private func submitScore() {
        if let score = Int(currentInput) {
            onSubmit(score)
            clear()
        }
    }
    
    private func farkle() {
        onFarkle()
        clear()
    }
}

#Preview {
    ScoreInputView(currentInput: .constant("")) { score in
        print("Score submitted: \(score)")
    } onFarkle: {
        print("Farkle!")
    }
}

