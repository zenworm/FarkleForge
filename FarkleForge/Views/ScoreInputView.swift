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
    
    // Dark green background color #1B2918
    private let containerColor = Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0)
    
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
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Numbers on the right
                Text(currentInput.isEmpty ? "" : currentInput)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal)
            }
            .frame(height: 80)
            .background(containerColor)
            .cornerRadius(12)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentInput.isEmpty)
            
            // Number pad
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["7", "8", "9", "4", "5", "6", "1", "2", "3"], id: \.self) { number in
                    CalculatorButton(
                        title: number,
                        foregroundColor: .white
                    ) {
                        appendNumber(number)
                    }
                }
                
                CalculatorButton(
                    title: "00",
                    foregroundColor: .blue.opacity(0.7)
                ) {
                    appendShortcut("00")
                }
                
                CalculatorButton(
                    title: "0",
                    foregroundColor: .white
                ) {
                    appendNumber("0")
                }
                
                CalculatorButton(
                    title: "50",
                    foregroundColor: .blue.opacity(0.7)
                ) {
                    appendShortcut("50")
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
                        .background(containerColor)
                        .foregroundColor(.red)
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                            .stroke(.red, lineWidth: 1)
                        )
                }
                
                Button(action: submitScore) {
                    Text("Bank")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(containerColor)
                        .foregroundColor(currentInput.isEmpty ? .gray : .green)
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                            .stroke(.green, lineWidth: 1)
                        )
                }
                .disabled(currentInput.isEmpty)
            }
        }
        .padding()
        .background(containerColor)
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

