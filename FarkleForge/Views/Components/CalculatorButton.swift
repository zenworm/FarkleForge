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

    init(
        title: String,
        foregroundColor: Color = .white, // #FFFFFF default
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("GeistMono-Regular", size: 34))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 60)
        .opacity(isPressed ? 0.4 : 1.0)
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

