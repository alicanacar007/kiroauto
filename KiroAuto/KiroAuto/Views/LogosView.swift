//
//  LogosView.swift
//  KiroAuto
//
//  AWS and Kiro.app logo components
//

import SwiftUI

// MARK: - AWS Logo
struct AWSLogo: View {
    var size: CGFloat = 40
    var color: Color = .orange
    
    var body: some View {
        ZStack {
            // AWS arrow shape
            Path { path in
                let width = size
                let height = size * 0.6
                let arrowWidth = width * 0.3
                
                // Main arrow body
                path.move(to: CGPoint(x: width * 0.1, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.1))
                path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.9))
                path.closeSubpath()
                
                // Arrow point
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.1))
                path.addLine(to: CGPoint(x: width * 0.5 + arrowWidth, y: height * 0.3))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.5 - arrowWidth, y: height * 0.3))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Kiro Logo
struct KiroLogo: View {
    var size: CGFloat = 40
    var color: Color = .blue
    
    var body: some View {
        ZStack {
            // Kiro "K" letter stylized
            Path { path in
                let width = size
                let height = size
                
                // Vertical line
                path.move(to: CGPoint(x: width * 0.25, y: height * 0.1))
                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.9))
                
                // Top diagonal
                path.move(to: CGPoint(x: width * 0.25, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.15))
                
                // Bottom diagonal
                path.move(to: CGPoint(x: width * 0.25, y: height * 0.5))
                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.85))
            }
            .stroke(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: size * 0.15, lineCap: .round, lineJoin: .round)
            )
            
            // Decorative circle
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size * 1.1, height: size * 1.1)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Logo Badge View
struct LogoBadge: View {
    let logo: AnyView
    let text: String
    var size: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 8) {
            logo
                .frame(width: size, height: size)
            
            Text(text)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Logo Header View
struct LogoHeaderView: View {
    var body: some View {
        HStack(spacing: 20) {
            LogoBadge(
                logo: AnyView(AWSLogo(size: 28, color: .orange)),
                text: "AWS",
                size: 28
            )
            
            LogoBadge(
                logo: AnyView(KiroLogo(size: 28, color: .blue)),
                text: "kiro.app",
                size: 28
            )
        }
        .padding(.top, 8)
    }
}

