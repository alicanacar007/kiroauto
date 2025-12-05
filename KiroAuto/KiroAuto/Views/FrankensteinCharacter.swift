//
//  FrankensteinCharacter.swift
//  KiroAuto
//
//  Cartoon Frankenstein character component
//

import SwiftUI

struct FrankensteinCharacter: View {
    var size: CGFloat = 120
    var animated: Bool = true
    @State private var headBob: CGFloat = 0
    @State private var eyeBlink: Bool = false
    
    var body: some View {
        ZStack {
            // Character body
            characterBody
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }
    
    private var characterBody: some View {
        ZStack {
            // Head
            headShape
                .offset(y: headBob)
            
            // Body
            bodyShape
                .offset(y: size * 0.35)
        }
    }
    
    private var headShape: some View {
        ZStack {
            // Head base (square-ish, like classic Frankenstein)
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(
                    LinearGradient(
                        colors: [Color.frankensteinGreen, Color.frankensteinDarkGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.7, height: size * 0.6)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Stitches on head
            headStitches
            
            // Face features
            faceFeatures
        }
    }
    
    private var headStitches: some View {
        ZStack {
            // Top stitches
            ForEach(0..<3, id: \.self) { i in
                StitchMark()
                    .fill(Color.frankensteinStitch)
                    .frame(width: size * 0.08, height: size * 0.06)
                    .offset(x: (CGFloat(i) - 1) * size * 0.2, y: -size * 0.25)
            }
            
            // Side stitches
            StitchMark()
                .fill(Color.frankensteinStitch)
                .frame(width: size * 0.06, height: size * 0.08)
                .offset(x: -size * 0.3, y: -size * 0.1)
            
            StitchMark()
                .fill(Color.frankensteinStitch)
                .frame(width: size * 0.06, height: size * 0.08)
                .offset(x: size * 0.3, y: -size * 0.1)
        }
    }
    
    private var faceFeatures: some View {
        ZStack {
            // Eyes
            HStack(spacing: size * 0.15) {
                // Left eye
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.12, height: size * 0.12)
                    
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.08, height: size * 0.08)
                        .offset(x: size * 0.01, y: size * 0.01)
                        .opacity(eyeBlink ? 0 : 1)
                }
                .offset(x: -size * 0.08, y: -size * 0.05)
                
                // Right eye
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.12, height: size * 0.12)
                    
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.08, height: size * 0.08)
                        .offset(x: size * 0.01, y: size * 0.01)
                        .opacity(eyeBlink ? 0 : 1)
                }
                .offset(x: size * 0.08, y: -size * 0.05)
            }
            
            // Mouth (simple line)
            Rectangle()
                .fill(Color.black)
                .frame(width: size * 0.2, height: size * 0.03)
                .offset(y: size * 0.1)
            
            // Bolts on neck
            HStack(spacing: size * 0.25) {
                BoltDecoration(size: size * 0.12, color: .frankensteinBolt)
                    .offset(x: -size * 0.15, y: size * 0.25)
                
                BoltDecoration(size: size * 0.12, color: .frankensteinBolt)
                    .offset(x: size * 0.15, y: size * 0.25)
            }
        }
    }
    
    private var bodyShape: some View {
        ZStack {
            // Body (simplified rectangle)
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(
                    LinearGradient(
                        colors: [Color.frankensteinDarkGreen, Color.frankensteinGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.6, height: size * 0.4)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            
            // Body stitches
            VStack(spacing: size * 0.08) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: size * 0.15) {
                        StitchMark()
                            .fill(Color.frankensteinStitch)
                            .frame(width: size * 0.06, height: size * 0.08)
                        
                        StitchMark()
                            .fill(Color.frankensteinStitch)
                            .frame(width: size * 0.06, height: size * 0.08)
                    }
                }
            }
        }
    }
    
    private func startAnimations() {
        // Head bobbing animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            headBob = size * 0.02
        }
        
        // Eye blinking animation
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                eyeBlink = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    eyeBlink = false
                }
            }
        }
    }
}

// MARK: - Character Badge View
struct FrankensteinCharacterBadge: View {
    var size: CGFloat = 100
    var showLabel: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            FrankensteinCharacter(size: size, animated: true)
            
            if showLabel {
                Text("Frankenstein")
                    .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                    .foregroundColor(.frankensteinDarkGreen)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .modifier(StitchedBorder(cornerRadius: 16, stitchCount: 4))
    }
}

// MARK: - Floating Character View
struct FloatingFrankenstein: View {
    var size: CGFloat = 80
    @State private var floatOffset: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        FrankensteinCharacter(size: size, animated: true)
            .rotationEffect(.degrees(rotation))
            .offset(y: floatOffset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true)
                ) {
                    floatOffset = -10
                }
                
                withAnimation(
                    Animation.linear(duration: 8.0)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 5
                }
            }
    }
}


