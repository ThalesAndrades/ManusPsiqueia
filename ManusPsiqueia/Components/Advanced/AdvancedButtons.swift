//
//  AdvancedButtons.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Advanced button styles for mental health platform
struct MentalHealthButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        case calm
        case energetic
        case therapeutic
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        case extraLarge
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            case .extraLarge: return 60
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            case .extraLarge: return 20
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            case .extraLarge: return 20
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            hapticFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                        .accessibilityHidden(true) // Hide decorative icons from VoiceOver
                }
                
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundGradient)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        // Accessibility improvements
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityRole(.button)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityValue(accessibilityValue)
    }
    
    // MARK: - Accessibility Support
    
    /// Computed accessibility label that provides context for the button's function
    private var accessibilityLabel: String {
        var label = title
        
        // Add context based on button style for mental health appropriateness
        switch style {
        case .therapeutic:
            label += ", botão terapêutico"
        case .calm:
            label += ", ação tranquilizante"
        case .energetic:
            label += ", ação estimulante"
        case .destructive:
            label += ", ação de remoção"
        default:
            break
        }
        
        return label
    }
    
    /// Accessibility hint that explains what happens when the button is pressed
    private var accessibilityHint: String {
        switch style {
        case .destructive:
            return "Toque duas vezes para confirmar esta ação irreversível"
        case .therapeutic:
            return "Toque duas vezes para acessar ferramentas terapêuticas"
        case .calm:
            return "Toque duas vezes para ação de relaxamento"
        case .energetic:
            return "Toque duas vezes para ação energizante"
        default:
            return "Toque duas vezes para ativar"
        }
    }
    
    /// Additional accessibility traits based on button style
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        
        switch style {
        case .destructive:
            traits.insert(.isDestructive)
        case .primary:
            traits.insert(.isKeyboardKey)
        default:
            break
        }
        
        return traits
    }
    
    /// Accessibility value for buttons that represent a state
    private var accessibilityValue: String? {
        // Can be used for toggle buttons or buttons that represent a current state
        return nil
    }
    
    private var backgroundGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [Color(hex: "8B5CF6"), Color(hex: "A855F7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tertiary:
            return LinearGradient(
                colors: [Color.clear, Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .destructive:
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calm:
            return LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .energetic:
            return LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .therapeutic:
            return LinearGradient(
                colors: [Color.green.opacity(0.7), Color.mint.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive, .calm, .energetic, .therapeutic:
            return .white
        case .secondary:
            return .primary
        case .tertiary:
            return Color(hex: "8B5CF6")
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .tertiary:
            return Color(hex: "8B5CF6").opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        style == .tertiary ? 1.5 : 0
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        case .extraLarge: return 14
        }
    }
}

/// Floating Action Button for mental health actions
struct MentalHealthFAB: View {
    let icon: String
    let action: () -> Void
    let style: FABStyle
    
    @State private var isPressed = false
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    enum FABStyle {
        case primary
        case secondary
        case emergency
        
        var colors: [Color] {
            switch self {
            case .primary:
                return [Color(hex: "8B5CF6"), Color(hex: "A855F7")]
            case .secondary:
                return [Color.blue, Color.cyan]
            case .emergency:
                return [Color.red, Color.orange]
            }
        }
    }
    
    init(
        icon: String,
        style: FABStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            hapticFeedback.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: style.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: style.colors.first?.opacity(0.3) ?? .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

/// Mood tracking button with emotional states
struct MoodButton: View {
    let mood: MoodState
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum MoodState: String, CaseIterable {
        case veryHappy = "😄"
        case happy = "😊"
        case neutral = "😐"
        case sad = "😔"
        case verySad = "😢"
        case anxious = "😰"
        case angry = "😠"
        case calm = "😌"
        case excited = "🤗"
        case tired = "😴"
        
        var name: String {
            switch self {
            case .veryHappy: return "Muito Feliz"
            case .happy: return "Feliz"
            case .neutral: return "Neutro"
            case .sad: return "Triste"
            case .verySad: return "Muito Triste"
            case .anxious: return "Ansioso"
            case .angry: return "Irritado"
            case .calm: return "Calmo"
            case .excited: return "Animado"
            case .tired: return "Cansado"
            }
        }
        
        var color: Color {
            switch self {
            case .veryHappy, .happy, .excited: return .green
            case .neutral, .calm: return .blue
            case .sad, .verySad, .tired: return .indigo
            case .anxious: return .orange
            case .angry: return .red
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.rawValue)
                    .font(.system(size: 32))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                Text(mood.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? mood.color : .secondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                        ? mood.color.opacity(0.1)
                        : Color(.systemGray6)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? mood.color : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

/// Therapeutic action button with progress indication
struct TherapeuticActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let progress: Double?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String,
        progress: Double? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with progress ring
                ZStack {
                    if let progress = progress {
                        Circle()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 3)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.purple)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let progress = progress {
                        Text("\(Int(progress * 100))% concluído")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

/// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MentalHealthButton("Iniciar Sessão", icon: "brain.head.profile", style: .primary) {}
        
        MentalHealthButton("Salvar Progresso", icon: "checkmark.circle", style: .therapeutic) {}
        
        HStack {
            MoodButton(mood: .happy, isSelected: true) {}
            MoodButton(mood: .neutral, isSelected: false) {}
            MoodButton(mood: .anxious, isSelected: false) {}
        }
        
        TherapeuticActionButton(
            "Exercício de Respiração",
            subtitle: "Técnica 4-7-8 para relaxamento",
            icon: "lungs",
            progress: 0.65
        ) {}
        
        MentalHealthFAB(icon: "plus", style: .primary) {}
    }
    .padding()
}
