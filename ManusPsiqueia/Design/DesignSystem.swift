//
//  DesignSystem.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Apple HIG Compliant Design System
struct DesignSystem {
    
    // MARK: - Colors (Using Semantic Colors)
    struct Colors {
        // Primary Brand Colors
        static let primary = Color("PrimaryColor") ?? Color(red: 0.4, green: 0.2, blue: 0.8)
        static let secondary = Color("SecondaryColor") ?? Color(red: 0.2, green: 0.6, blue: 0.9)
        static let accent = Color("AccentColor") ?? Color(red: 0.9, green: 0.3, blue: 0.5)
        
        // Semantic Colors (Adapts to light/dark mode)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)
        static let tertiaryLabel = Color(.tertiaryLabel)
        static let quaternaryLabel = Color(.quaternaryLabel)
        
        static let separator = Color(.separator)
        static let opaqueSeparator = Color(.opaqueSeparator)
        
        // Status Colors
        static let success = Color(.systemGreen)
        static let warning = Color(.systemOrange)
        static let error = Color(.systemRed)
        static let info = Color(.systemBlue)
    }
    
    // MARK: - Typography (Following Apple's Type Scale)
    struct Typography {
        // Large Title
        static let largeTitle = Font.largeTitle
        static let largeTitleWeight: Font.Weight = .regular
        
        // Title
        static let title1 = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        
        // Headlines
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        
        // Body
        static let body = Font.body
        static let callout = Font.callout
        
        // Captions
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        
        // Custom styles maintaining Apple's design principles
        static func customFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
            return .system(size: size, weight: weight, design: design)
        }
    }
    
    // MARK: - Spacing (8pt Grid System)
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
        
        // Specific spacing for components
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let buttonHeight: CGFloat = 44 // Apple's minimum touch target
        static let inputHeight: CGFloat = 44
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        
        // iOS 15+ style corner radius for cards and modals
        static let card: CGFloat = 12
        static let modal: CGFloat = 16
        static let button: CGFloat = 12
    }
    
    // MARK: - Shadows (Following iOS depth principles)
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation (Apple's preferred timing curves)
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.25)
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.25)
        
        // Interactive animations
        static let interactive = SwiftUI.Animation.interactiveSpring(response: 0.3, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Haptic Feedback
    struct Haptics {
        static func light() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        static func medium() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        static func heavy() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        static func success() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        static func warning() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
        
        static func error() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
        
        static func selection() {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
}

// MARK: - Environment Values for Dynamic Type Support
struct DynamicTypeSize {
    static func scaledFont(for font: Font, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        return font
    }
    
    static func scaledValue(for value: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> CGFloat {
        return value
    }
}

// MARK: - Accessibility Helpers
struct AccessibilityHelper {
    static func voiceOverLabel(for element: String, hint: String? = nil) -> some ViewModifier {
        return AccessibilityModifier(label: element, hint: hint)
    }
}

struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Reduce Motion Support
extension View {
    func reduceMotionSensitive<T: Equatable>(
        _ animation: SwiftUI.Animation?,
        value: T
    ) -> some View {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? nil : animation,
            value: value
        )
    }
}