//
//  SplashView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct SplashView: View {
    let onStartGame: () -> Void
    private let bankColor = Color(red: 96/255.0, green: 201/255.0, blue: 70/255.0) // #60C946
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 27/255.0, green: 41/255.0, blue: 24/255.0) // #1B2918
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image("wtf")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                
                Button(action: onStartGame) {
                    Text("Start game")
                        .font(.custom("Daydream", size: 20))
                        .fontWeight(.bold)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .foregroundColor(bankColor)
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                            .stroke(bankColor, lineWidth: 2)
                        )
                }
            }
        }
    }
}

#Preview {
    SplashView(onStartGame: {})
}

