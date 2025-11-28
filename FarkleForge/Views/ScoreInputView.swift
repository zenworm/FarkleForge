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
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Display current input
            HStack {
                // Reset button on the left (only shown when there's input)
                if !currentInput.isEmpty {
                    Button(action: clear) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Numbers on the right
                Text(currentInput.isEmpty ? "0" : currentInput)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal)
            }
            .frame(height: 80)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentInput.isEmpty)
            
            // Number pad
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3"], id: \.self) { number in
                    CalculatorButton(title: number) {
                        appendNumber(number)
                    }
                }
                
                CalculatorButton(
                    title: "50",
                    backgroundColor: .blue.opacity(0.2),
                    foregroundColor: .blue
                ) {
                    appendShortcut("50")
                }
                
                CalculatorButton(title: "0") {
                    appendNumber("0")
                }
                
                CalculatorButton(
                    title: "00",
                    backgroundColor: .blue.opacity(0.2),
                    foregroundColor: .blue
                ) {
                    appendShortcut("00")
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: farkle) {
                    Text("Farkle")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Button(action: submitScore) {
                    Text("Bank")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(currentInput.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .disabled(currentInput.isEmpty)
            }
        }
        .padding()
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

