//
//  CalculatorButton.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct CalculatorButton: View {
    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    init(
        title: String,
        backgroundColor: Color = .gray.opacity(0.3),
        foregroundColor: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(4)
        }
        .frame(height: 60)
    }
}

#Preview {
    CalculatorButton(title: "5") {
        print("Button tapped")
    }
    .padding()
}

