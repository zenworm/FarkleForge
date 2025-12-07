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
    
    // Button styling colors
    private let buttonBackgroundColor = Color(red: 23/255.0, green: 32/255.0, blue: 21/255.0) // #172015
    private let borderColor = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0).opacity(0.25) // #60C946 at 25%
    private let shadowColor = Color(red: 23/255.0, green: 32/255.0, blue: 21/255.0).opacity(0.6) // #172015 at 60%
    
    init(
        title: String,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(buttonBackgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(color: shadowColor, radius: 1, x: 4, y: 4)
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

