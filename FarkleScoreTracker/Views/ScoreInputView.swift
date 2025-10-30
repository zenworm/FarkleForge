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
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Display current input
            HStack {
                Spacer()
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
            
            // Quick action buttons
            HStack(spacing: 12) {
                CalculatorButton(
                    title: "50",
                    backgroundColor: .blue.opacity(0.2),
                    foregroundColor: .blue
                ) {
                    appendShortcut("50")
                }
                
                CalculatorButton(
                    title: "00",
                    backgroundColor: .blue.opacity(0.2),
                    foregroundColor: .blue
                ) {
                    appendShortcut("00")
                }
            }
            .frame(height: 60)
            
            // Number pad
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3"], id: \.self) { number in
                    CalculatorButton(title: number) {
                        appendNumber(number)
                    }
                }
                
                CalculatorButton(
                    title: "⌫",
                    backgroundColor: .orange.opacity(0.2),
                    foregroundColor: .orange
                ) {
                    backspace()
                }
                
                CalculatorButton(title: "0") {
                    appendNumber("0")
                }
                
                CalculatorButton(
                    title: "C",
                    backgroundColor: .red.opacity(0.2),
                    foregroundColor: .red
                ) {
                    clear()
                }
            }
            
            // Submit button
            Button(action: submitScore) {
                Text("Add to Score")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(currentInput.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(currentInput.isEmpty)
        }
        .padding()
    }
    
    private func appendNumber(_ number: String) {
        // Limit input length
        if currentInput.count < 6 {
            currentInput += number
        }
    }
    
    private func backspace() {
        if !currentInput.isEmpty {
            currentInput.removeLast()
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
}

#Preview {
    ScoreInputView(currentInput: .constant("")) { score in
        print("Score submitted: \(score)")
    }
}

