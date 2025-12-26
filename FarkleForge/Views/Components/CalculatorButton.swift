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
    let action: () -> Void
    
    @State private var isPressed = false
    
    // Button styling colors
    private let buttonBackgroundColor = Color(red: 23/255.0, green: 32/255.0, blue: 21/255.0) // #172015
    private let borderColor = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0).opacity(0.25) // #60C946 at 25%
    private let shadowColor = Color(red: 23/255.0, green: 32/255.0, blue: 21/255.0).opacity(0.6) // #172015 at 60%
    private let textColor = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) // #60C946
    
    init(
        title: String,
        foregroundColor: Color = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0), // #60C946 default
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Daydream", size: 30))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(buttonBackgroundColor)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: shadowColor, radius: 1, x: 4, y: 4)
        }
        .buttonStyle(.plain)
        .frame(height: 60)
        .offset(x: isPressed ? 2 : 0, y: isPressed ? 2 : 0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        var transaction = Transaction(animation: .linear(duration: 0.05))
                        transaction.disablesAnimations = false
                        withTransaction(transaction) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    var transaction = Transaction(animation: .linear(duration: 0.05))
                    transaction.disablesAnimations = false
                    withTransaction(transaction) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    CalculatorButton(title: "5") {
        print("Button tapped")
    }
    .padding()
}

