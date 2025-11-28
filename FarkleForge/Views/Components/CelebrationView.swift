//
//  CelebrationView.swift
//  FarkleScoreTracker
//
//  Created on 10/30/2025.
//

import SwiftUI

struct CelebrationView: View {
    let winnerName: String
    let onDismiss: () -> Void
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Confetti particles
            if showConfetti {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiParticle(index: index)
                }
            }
            
            // Celebration content
            VStack(spacing: 24) {
                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                
                // Winner text
                Text("\(winnerName) Wins!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(opacity)
                
                Text("Congratulations!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
                
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .opacity(opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .opacity(opacity)
        }
        .onAppear {
            // Animate confetti
            withAnimation(.easeOut(duration: 0.3)) {
                showConfetti = true
            }
            
            // Animate trophy
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 360
            }
            
            // Animate text
            withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

struct ConfettiParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = -300
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan, .mint]
    private let color: Color
    private let startX: CGFloat
    private let size: CGFloat
    
    init(index: Int) {
        self.index = index
        self.color = colors[index % colors.count]
        
        // Randomize starting position and size
        self.startX = CGFloat.random(in: -200...200)
        self.size = CGFloat.random(in: 6...12)
        self._xOffset = State(initialValue: startX)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 1.5)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                // Randomize animation parameters
                let randomDuration = Double.random(in: 2.5...4.5)
                let randomRotation = Double.random(in: 720...2160) // 2-6 full rotations
                let randomXMovement = CGFloat.random(in: -150...150)
                let randomDelay = Double.random(in: 0...0.5)
                
                // Delay the animation start slightly for staggered effect
                DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                    withAnimation(.linear(duration: randomDuration)) {
                        yOffset = 1200
                        xOffset = startX + randomXMovement
                        rotation = randomRotation
                    }
                    
                    // Fade out
                    withAnimation(.linear(duration: randomDuration * 0.7).delay(randomDuration * 0.3)) {
                        opacity = 0
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        CelebrationView(winnerName: "Alice", onDismiss: {})
    }
}

