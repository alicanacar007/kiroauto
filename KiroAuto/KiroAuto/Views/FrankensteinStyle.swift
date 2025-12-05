//
//  AppDesignSystem.swift
//  KiroAuto
//
//  Modern, high-end design system for Kiro Auto Remote Vibe Coder
//

import SwiftUI

// MARK: - Modern Color Palette
extension Color {
    // Primary brand colors - sophisticated blue gradient
    static let kiroPrimary = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let kiroPrimaryDark = Color(red: 0.15, green: 0.3, blue: 0.8)
    static let kiroPrimaryLight = Color(red: 0.3, green: 0.5, blue: 0.95)
    
    // Accent colors
    static let kiroAccent = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let kiroAccentSecondary = Color(red: 0.6, green: 0.8, blue: 1.0)
    
    // Neutral colors
    static let kiroBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let kiroCard = Color.white
    static let kiroSurface = Color(red: 0.97, green: 0.97, blue: 0.98)
    
    // Status colors
    static let kiroSuccess = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let kiroWarning = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let kiroError = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let kiroInfo = Color(red: 0.3, green: 0.6, blue: 0.9)
}

// MARK: - Modern Card Modifier
struct ModernCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 8
    var padding: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.kiroCard)
                    .shadow(color: .black.opacity(0.08), radius: shadowRadius, x: 0, y: 4)
            )
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .medium
    
    enum ButtonVariant {
        case primary
        case secondary
        case danger
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var padding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 13
            case .medium: return 15
            case .large: return 17
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .default))
            .foregroundColor(variant == .primary ? .white : (variant == .danger ? .white : .kiroPrimary))
            .padding(.horizontal, 24)
            .padding(.vertical, size.padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackground(for: variant))
                    .shadow(color: buttonShadowColor(for: variant), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func buttonBackground(for variant: ButtonVariant) -> LinearGradient {
        switch variant {
        case .primary:
            return LinearGradient(
                colors: [.kiroPrimary, .kiroPrimaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [.kiroCard, .kiroSurface],
                startPoint: .top,
                endPoint: .bottom
            )
        case .danger:
            return LinearGradient(
                colors: [.kiroError, .kiroError.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func buttonShadowColor(for variant: ButtonVariant) -> Color {
        switch variant {
        case .primary:
            return .kiroPrimary.opacity(0.4)
        case .secondary:
            return .black.opacity(0.1)
        case .danger:
            return .kiroError.opacity(0.4)
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.kiroCard)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.kiroPrimary.opacity(0.2), lineWidth: 1.5)
            )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let status: StatusType
    
    enum StatusType {
        case success
        case warning
        case error
        case info
        case running
        
        var color: Color {
            switch self {
            case .success: return .kiroSuccess
            case .warning: return .kiroWarning
            case .error: return .kiroError
            case .info: return .kiroInfo
            case .running: return .kiroPrimary
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .running: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if status == .running {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text.capitalized)
                .font(.system(size: 13, weight: .semibold, design: .default))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [status.color, status.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: status.color.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - View Extensions
extension View {
    func modernCard(cornerRadius: CGFloat = 16, padding: CGFloat = 24) -> some View {
        modifier(ModernCard(cornerRadius: cornerRadius, padding: padding))
    }
    
    func modernButton(variant: ModernButtonStyle.ButtonVariant = .primary, size: ModernButtonStyle.ButtonSize = .medium) -> some View {
        buttonStyle(ModernButtonStyle(variant: variant, size: size))
    }
}

// MARK: - Animated Pulse Effect
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    var duration: Double = 2.0
    var scale: CGFloat = 1.05
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.85 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsing(duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        modifier(PulseEffect(duration: duration, scale: scale))
    }
}

// MARK: - Gradient Background
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.kiroBackground,
                Color.kiroSurface.opacity(0.5),
                Color.kiroBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String?
    var color: Color = .kiroPrimary
    
    init(_ title: String, icon: String? = nil, color: Color = .kiroPrimary) {
        self.title = title
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(color)
        }
    }
}
