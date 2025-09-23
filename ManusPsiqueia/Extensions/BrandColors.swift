//
//  BrandColors.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

// MARK: - Brand Colors Extension

extension Color {
    /// Primary brand color for ManusPsiqueia
    static let brandPrimary = Color("BrandPrimary") ?? Color(red: 0.4, green: 0.2, blue: 0.8)
    
    /// Secondary brand color for ManusPsiqueia
    static let brandSecondary = Color("BrandSecondary") ?? Color(red: 0.2, green: 0.6, blue: 0.9)
    
    /// Brand gradient for logo and highlights
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [Color.brandPrimary, Color.brandSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Brand gradient for text
    static let brandTextGradient = LinearGradient(
        gradient: Gradient(colors: [Color.brandPrimary, Color.brandSecondary]),
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Brand Assets

extension Image {
    /// Main ManusPsiqueia logo
    static let manusLogo = Image("ManusLogo")
    
    /// Manus icon (template)
    static let manusIcon = Image("ManusIcon")
}