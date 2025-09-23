//
//  AppleHIGComponents.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

// MARK: - Apple HIG Compliant Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Spacing.buttonHeight)
            .background(
                isEnabled ?
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.primary,
                        DesignSystem.Colors.secondary
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.quaternaryLabel,
                        DesignSystem.Colors.quaternaryLabel
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .shadow(
                color: isEnabled ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear,
                radius: configuration.isPressed ? 5 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .reduceMotionSensitive(
                DesignSystem.Animation.spring,
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    DesignSystem.Haptics.light()
                }
            }
            .accessibilityRole(.button)
            .accessibilityAddTraits(isEnabled ? [] : .notEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.quaternaryLabel)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Spacing.buttonHeight)
            .background(DesignSystem.Colors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(
                        isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .reduceMotionSensitive(
                DesignSystem.Animation.spring,
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    DesignSystem.Haptics.light()
                }
            }
            .accessibilityRole(.button)
            .accessibilityAddTraits(isEnabled ? [] : .notEnabled)
    }
}

// MARK: - Apple HIG Compliant Text Fields
struct AppleStyleTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var accessibilityHint: String = ""
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.label)
                .fontWeight(.medium)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(DesignSystem.Typography.body)
            .textFieldStyle(.plain)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .focused($isFocused)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .accessibilityLabel(title)
            .accessibilityHint(accessibilityHint)
            .onChange(of: isFocused) { focused in
                if focused {
                    DesignSystem.Haptics.selection()
                }
            }
        }
    }
}

// MARK: - Apple HIG Compliant Cards
struct AppleStyleCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = DesignSystem.Colors.secondaryBackground
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.card
    var shadow: DesignSystem.Shadows.Shadow = DesignSystem.Shadows.medium
    
    init(
        backgroundColor: Color = DesignSystem.Colors.secondaryBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: DesignSystem.Shadows.Shadow = DesignSystem.Shadows.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Apple HIG Compliant Loading View
struct AppleLoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.5)
                .accessibilityLabel("Carregando")
            
            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            DesignSystem.Colors.secondaryBackground,
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Apple HIG Compliant Alert Manager
class AlertManager: ObservableObject {
    @Published var currentAlert: AlertConfig?
    
    struct AlertConfig: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let primaryAction: AlertAction
        let secondaryAction: AlertAction?
        
        struct AlertAction {
            let title: String
            let style: Style
            let action: () -> Void
            
            enum Style {
                case `default`
                case cancel
                case destructive
            }
        }
    }
    
    func showAlert(
        title: String,
        message: String,
        primaryAction: AlertConfig.AlertAction,
        secondaryAction: AlertConfig.AlertAction? = nil
    ) {
        DesignSystem.Haptics.warning()
        currentAlert = AlertConfig(
            title: title,
            message: message,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }
    
    func showError(_ error: Error) {
        showAlert(
            title: "Erro",
            message: error.localizedDescription,
            primaryAction: AlertConfig.AlertAction(
                title: "OK",
                style: .default,
                action: {}
            )
        )
    }
    
    func showSuccess(message: String) {
        DesignSystem.Haptics.success()
        showAlert(
            title: "Sucesso",
            message: message,
            primaryAction: AlertConfig.AlertAction(
                title: "OK",
                style: .default,
                action: {}
            )
        )
    }
}

// MARK: - Alert View Modifier
struct AlertModifier: ViewModifier {
    @ObservedObject var alertManager: AlertManager
    
    func body(content: Content) -> some View {
        content
            .alert(
                alertManager.currentAlert?.title ?? "",
                isPresented: .constant(alertManager.currentAlert != nil),
                presenting: alertManager.currentAlert
            ) { alert in
                Button(alert.primaryAction.title, role: buttonRole(for: alert.primaryAction.style)) {
                    alert.primaryAction.action()
                    alertManager.currentAlert = nil
                }
                
                if let secondaryAction = alert.secondaryAction {
                    Button(secondaryAction.title, role: buttonRole(for: secondaryAction.style)) {
                        secondaryAction.action()
                        alertManager.currentAlert = nil
                    }
                }
            } message: { alert in
                Text(alert.message)
            }
    }
    
    private func buttonRole(for style: AlertManager.AlertConfig.AlertAction.Style) -> ButtonRole? {
        switch style {
        case .default:
            return nil
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}

extension View {
    func alertManager(_ alertManager: AlertManager) -> some View {
        modifier(AlertModifier(alertManager: alertManager))
    }
}

// MARK: - Apple HIG Compliant Navigation
struct AppleStyleNavigationView<Content: View>: View {
    let title: String
    let content: Content
    var showBackButton: Bool = true
    var onBack: (() -> Void)?
    
    init(
        title: String,
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
                .navigationBarBackButtonHidden(!showBackButton)
                .toolbar {
                    if showBackButton && onBack != nil {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                DesignSystem.Haptics.light()
                                onBack?()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 17, weight: .medium))
                                    Text("Voltar")
                                        .font(.system(size: 17))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .accessibilityLabel("Voltar")
                            .accessibilityHint("Retorna à tela anterior")
                        }
                    }
                }
        }
    }
}

// MARK: - Apple HIG Compliant Empty State
struct AppleEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.label)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}