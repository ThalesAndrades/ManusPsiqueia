//
//  ManusPsiqueiaUI.swift
//  ManusPsiqueiaUI
//
//  Módulo de componentes UI reutilizáveis para ManusPsiqueia
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 ManusPsiqueia. All rights reserved.
//

import SwiftUI

// MARK: - Public API

/// Namespace principal para todos os componentes UI do ManusPsiqueia
public struct ManusPsiqueiaUI {
    
    // MARK: - Version Info
    
    public static let version = "1.0.0"
    public static let buildNumber = "1"
    
    // MARK: - Theme Configuration
    
    public static var theme: Theme = .default
    
    // MARK: - Initialization
    
    /// Configura o módulo UI com tema personalizado
    /// - Parameter theme: Tema a ser aplicado globalmente
    public static func configure(with theme: Theme) {
        self.theme = theme
    }
}

// MARK: - Theme System

public struct Theme {
    
    // MARK: - Colors
    
    public struct Colors {
        public let primary: Color
        public let secondary: Color
        public let accent: Color
        public let background: Color
        public let surface: Color
        public let error: Color
        public let warning: Color
        public let success: Color
        public let text: TextColors
        
        public struct TextColors {
            public let primary: Color
            public let secondary: Color
            public let disabled: Color
            public let onPrimary: Color
            public let onSecondary: Color
        }
        
        public init(
            primary: Color,
            secondary: Color,
            accent: Color,
            background: Color,
            surface: Color,
            error: Color,
            warning: Color,
            success: Color,
            text: TextColors
        ) {
            self.primary = primary
            self.secondary = secondary
            self.accent = accent
            self.background = background
            self.surface = surface
            self.error = error
            self.warning = warning
            self.success = success
            self.text = text
        }
    }
    
    // MARK: - Typography
    
    public struct Typography {
        public let largeTitle: Font
        public let title1: Font
        public let title2: Font
        public let title3: Font
        public let headline: Font
        public let body: Font
        public let callout: Font
        public let subheadline: Font
        public let footnote: Font
        public let caption1: Font
        public let caption2: Font
        
        public init(
            largeTitle: Font = .largeTitle,
            title1: Font = .title,
            title2: Font = .title2,
            title3: Font = .title3,
            headline: Font = .headline,
            body: Font = .body,
            callout: Font = .callout,
            subheadline: Font = .subheadline,
            footnote: Font = .footnote,
            caption1: Font = .caption,
            caption2: Font = .caption2
        ) {
            self.largeTitle = largeTitle
            self.title1 = title1
            self.title2 = title2
            self.title3 = title3
            self.headline = headline
            self.body = body
            self.callout = callout
            self.subheadline = subheadline
            self.footnote = footnote
            self.caption1 = caption1
            self.caption2 = caption2
        }
    }
    
    // MARK: - Spacing
    
    public struct Spacing {
        public let xs: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat
        public let xxl: CGFloat
        
        public init(
            xs: CGFloat = 4,
            sm: CGFloat = 8,
            md: CGFloat = 16,
            lg: CGFloat = 24,
            xl: CGFloat = 32,
            xxl: CGFloat = 48
        ) {
            self.xs = xs
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
            self.xxl = xxl
        }
    }
    
    // MARK: - Corner Radius
    
    public struct CornerRadius {
        public let small: CGFloat
        public let medium: CGFloat
        public let large: CGFloat
        public let extraLarge: CGFloat
        
        public init(
            small: CGFloat = 8,
            medium: CGFloat = 12,
            large: CGFloat = 16,
            extraLarge: CGFloat = 24
        ) {
            self.small = small
            self.medium = medium
            self.large = large
            self.extraLarge = extraLarge
        }
    }
    
    // MARK: - Properties
    
    public let colors: Colors
    public let typography: Typography
    public let spacing: Spacing
    public let cornerRadius: CornerRadius
    
    // MARK: - Initialization
    
    public init(
        colors: Colors,
        typography: Typography = Typography(),
        spacing: Spacing = Spacing(),
        cornerRadius: CornerRadius = CornerRadius()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Default Theme

extension Theme {
    
    public static let `default` = Theme(
        colors: Colors(
            primary: Color(red: 0.2, green: 0.6, blue: 0.9),
            secondary: Color(red: 0.5, green: 0.5, blue: 0.5),
            accent: Color(red: 0.9, green: 0.4, blue: 0.2),
            background: Color(UIColor.systemBackground),
            surface: Color(UIColor.secondarySystemBackground),
            error: Color(red: 0.9, green: 0.2, blue: 0.2),
            warning: Color(red: 0.9, green: 0.7, blue: 0.2),
            success: Color(red: 0.2, green: 0.8, blue: 0.3),
            text: Colors.TextColors(
                primary: Color(UIColor.label),
                secondary: Color(UIColor.secondaryLabel),
                disabled: Color(UIColor.tertiaryLabel),
                onPrimary: Color.white,
                onSecondary: Color.white
            )
        )
    )
    
    public static let dark = Theme(
        colors: Colors(
            primary: Color(red: 0.3, green: 0.7, blue: 1.0),
            secondary: Color(red: 0.6, green: 0.6, blue: 0.6),
            accent: Color(red: 1.0, green: 0.5, blue: 0.3),
            background: Color(UIColor.systemBackground),
            surface: Color(UIColor.secondarySystemBackground),
            error: Color(red: 1.0, green: 0.3, blue: 0.3),
            warning: Color(red: 1.0, green: 0.8, blue: 0.3),
            success: Color(red: 0.3, green: 0.9, blue: 0.4),
            text: Colors.TextColors(
                primary: Color(UIColor.label),
                secondary: Color(UIColor.secondaryLabel),
                disabled: Color(UIColor.tertiaryLabel),
                onPrimary: Color.black,
                onSecondary: Color.black
            )
        )
    )
}

// MARK: - Environment Key

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    
    /// Aplica o tema do ManusPsiqueia à view
    /// - Parameter theme: Tema a ser aplicado
    /// - Returns: View com o tema aplicado
    public func manusPsiqueiaTheme(_ theme: Theme = ManusPsiqueiaUI.theme) -> some View {
        self.environment(\.theme, theme)
    }
}
