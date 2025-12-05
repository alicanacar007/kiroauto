//
//  SiriCircleView.swift
//  KiroAuto
//
//  Created by Ali Can Acar on 12/5/25.
//

import SwiftUI

struct SiriCircleView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var waveOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Background blur overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss on tap outside
                }
            
            // Siri circle in center
            VStack(spacing: 20) {
                ZStack {
                    // Outer pulsing circles (wave effect)
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.white.opacity(waveOpacity), lineWidth: 3)
                            .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0.0 : waveOpacity)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    // Microphone icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // "Listening..." text
                Text("Listening...")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
        }
        .transition(.opacity)
        .onAppear {
            isAnimating = true
            pulseScale = 1.1
        }
    }
}

#Preview {
    SiriCircleView()
        .frame(width: 800, height: 600)
}



