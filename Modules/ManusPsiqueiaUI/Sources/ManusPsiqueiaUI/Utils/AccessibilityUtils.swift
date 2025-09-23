//
//  AccessibilityUtils.swift
//  ManusPsiqueiaUI
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Foundation

/// Comprehensive accessibility utilities for ManusPsiqueia
public struct AccessibilityUtils {
    
    /// Standard accessibility traits for mental health app components
    public enum A11yTraits {
        public static let button = AccessibilityTraits.isButton
        public static let header = AccessibilityTraits.isHeader
        public static let textField = AccessibilityTraits.allowsDirectInteraction
        public static let slider = AccessibilityTraits.adjustable
        public static let tabItem = AccessibilityTraits.isButton
        public static let navigationButton = AccessibilityTraits([.isButton])
        public static let secureField = AccessibilityTraits([.allowsDirectInteraction])
        public static let submitButton = AccessibilityTraits([.isButton])
        public static let destructiveButton = AccessibilityTraits([.isButton])
    }
    
    /// Voice accessibility descriptions for mental health context
    public enum VoiceDescriptions {
        // Form fields
        public static let emailField = "Campo de e-mail. Insira seu endereço de e-mail para acessar o aplicativo."
        public static let passwordField = "Campo de senha. Insira sua senha de forma segura."
        public static let moodField = "Campo de humor. Descreva como você está se sentindo hoje."
        public static let diaryField = "Editor de diário. Escreva sobre seus pensamentos e sentimentos."
        
        // Buttons
        public static let loginButton = "Botão entrar. Toque para fazer login no aplicativo."
        public static let saveButton = "Botão salvar. Toque para salvar suas informações."
        public static let cancelButton = "Botão cancelar. Toque para cancelar a ação atual."
        public static let nextButton = "Botão próximo. Toque para ir para a próxima tela."
        public static let previousButton = "Botão anterior. Toque para voltar à tela anterior."
        
        // Navigation
        public static let homeTab = "Aba início. Acesse sua tela principal."
        public static let sessionsTab = "Aba sessões. Visualize e agende suas sessões."
        public static let progressTab = "Aba progresso. Acompanhe seu desenvolvimento."
        public static let profileTab = "Aba perfil. Gerencie suas informações pessoais."
        
        // Mood and scales
        public static let moodScale = "Escala de humor de 1 a 10. Deslize para ajustar seu nível de humor."
        public static let anxietyScale = "Escala de ansiedade de 1 a 10. Deslize para ajustar seu nível de ansiedade."
        public static let energyScale = "Escala de energia de 1 a 10. Deslize para ajustar seu nível de energia."
        
        // Payment
        public static let paymentButton = "Botão de pagamento. Toque para processar pagamento seguro."
        public static let subscriptionButton = "Botão de assinatura. Toque para assinar o plano premium."
    }
    
    /// Accessibility hints for enhanced user guidance
    public enum AccessibilityHints {
        public static let formValidation = "Certifique-se de preencher todos os campos obrigatórios."
        public static let secureInput = "Suas informações são protegidas e criptografadas."
        public static let scaleAdjustment = "Deslize para cima ou para baixo para ajustar o valor."
        public static let buttonTap = "Toque duas vezes para ativar."
        public static let navigationGesture = "Deslize para navegar entre as opções."
        public static let diaryPrivacy = "Suas entradas de diário são privadas e seguras."
        public static let paymentSecurity = "Pagamento processado com segurança pelo Stripe."
    }
    
    /// Generates dynamic accessibility labels based on context
    public static func dynamicLabel(for component: String, value: Any? = nil) -> String {
        switch component {
        case "mood_slider":
            if let value = value as? Double {
                return "Escala de humor. Valor atual: \(Int(value)) de 10"
            }
            return "Escala de humor"
        case "anxiety_slider":
            if let value = value as? Double {
                return "Escala de ansiedade. Valor atual: \(Int(value)) de 10"
            }
            return "Escala de ansiedade"
        case "text_count":
            if let count = value as? Int {
                return "Contador de caracteres: \(count) caracteres"
            }
            return "Contador de caracteres"
        case "validation_error":
            if let error = value as? String {
                return "Erro de validação: \(error)"
            }
            return "Erro de validação"
        default:
            return component
        }
    }
    
    /// Accessibility announcements for state changes
    public static func announceStateChange(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Screen reader announcements for navigation
    public static func announceScreenChange(to screenName: String) {
        UIAccessibility.post(notification: .screenChanged, argument: "Navegou para \(screenName)")
    }
    
    /// Layout change announcements
    public static func announceLayoutChange(description: String) {
        UIAccessibility.post(notification: .layoutChanged, argument: description)
    }
}

/// SwiftUI View extension for easy accessibility implementation
public extension View {
    
    /// Applies comprehensive accessibility to text fields
    func mentalHealthAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityTraits(traits)
    }
    
    /// Applies accessibility to buttons with mental health context
    func buttonAccessibility(
        label: String,
        hint: String = AccessibilityUtils.AccessibilityHints.buttonTap,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityTraits(AccessibilityUtils.A11yTraits.button)
            .accessibilityAddTraits(isEnabled ? [] : .isNotEnabled)
    }
    
    /// Applies accessibility to sliders and adjustable elements
    func sliderAccessibility(
        label: String,
        value: Double,
        range: ClosedRange<Double>,
        hint: String = AccessibilityUtils.AccessibilityHints.scaleAdjustment
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value)) de \(Int(range.upperBound))")
            .accessibilityHint(hint)
            .accessibilityTraits(AccessibilityUtils.A11yTraits.slider)
    }
    
    /// Applies accessibility to navigation elements
    func navigationAccessibility(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityTraits(AccessibilityUtils.A11yTraits.navigationButton)
    }
    
    /// Applies accessibility to tab items
    func tabAccessibility(
        label: String,
        isSelected: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityTraits(AccessibilityUtils.A11yTraits.tabItem)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Applies accessibility to headers
    func headerAccessibility(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityTraits(AccessibilityUtils.A11yTraits.header)
    }
    
    /// Groups related accessibility elements
    func accessibilityGroup() -> some View {
        self.accessibilityElement(children: .combine)
    }
    
    /// Hides decorative elements from accessibility
    func decorativeAccessibility() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// Announces dynamic content changes
    func announceContentChange(_ message: String) -> some View {
        self.onChange(of: message) { newValue in
            AccessibilityUtils.announceStateChange(newValue)
        }
    }
}

/// Accessibility configuration for VoiceOver optimization
public struct AccessibilityConfiguration {
    public static let reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
    public static let voiceOverEnabled = UIAccessibility.isVoiceOverRunning
    public static let switchControlEnabled = UIAccessibility.isSwitchControlRunning
    public static let assistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
    
    /// Determines if animations should be reduced for accessibility
    public static var shouldReduceAnimations: Bool {
        return reducedMotionEnabled || voiceOverEnabled
    }
    
    /// Determines if haptic feedback should be enhanced
    public static var shouldEnhanceHaptics: Bool {
        return voiceOverEnabled || switchControlEnabled
    }
    
    /// Font size adjustments for accessibility
    public static var accessibleFontSize: Font.TextStyle {
        if UIAccessibility.isBoldTextEnabled {
            return .title3
        }
        return .body
    }
}