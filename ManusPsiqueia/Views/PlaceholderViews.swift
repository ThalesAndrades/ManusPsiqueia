//
//  PlaceholderViews.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

// MARK: - Placeholder Views for Components Not Yet Implemented
// These views provide Apple HIG-compliant placeholders while full implementations are developed

struct AppleOnboardingFlow: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @AppStorage("hasShownOnboarding") private var hasShownOnboarding: Bool = false
    
    var body: some View {
        OnboardingView()
            .environmentObject(authManager)
            .onDisappear {
                hasShownOnboarding = true
            }
    }
}

struct AppleAuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AuthenticationView()
            .environmentObject(authManager)
    }
}

struct PsychologistMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        PsychologistDashboardView()
            .environmentObject(authManager)
            .environmentObject(subscriptionManager)
    }
}

// MARK: - Patient Flow Views
struct InsightsMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Insights") {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // Weekly Summary Card
                    AppleStyleCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text("Resumo Semanal")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.label)
                                
                                Spacer()
                            }
                            
                            Text("Sua análise semanal estará disponível em breve")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                    
                    // Mood Trends Card
                    AppleStyleCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.Colors.accent)
                                
                                Text("Tendências de Humor")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.label)
                                
                                Spacer()
                            }
                            
                            Text("Gráficos de tendências em desenvolvimento")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
        }
    }
}

struct GoalsMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Metas") {
            AppleEmptyStateView(
                icon: "target",
                title: "Defina suas metas",
                description: "Estabeleça objetivos pessoais e acompanhe seu progresso ao longo do tempo.",
                actionTitle: "Criar primeira meta"
            ) {
                // Action for creating first goal
                DesignSystem.Haptics.light()
            }
        }
    }
}

struct ProfileMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Perfil") {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // Profile Header
                    AppleStyleCard {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(DesignSystem.Colors.primary)
                                )
                            
                            Text(authManager.currentUser?.fullName ?? "Usuário")
                                .font(DesignSystem.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.label)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }
                    
                    // Settings Options
                    AppleStyleCard {
                        VStack(spacing: 0) {
                            ProfileOptionRow(
                                icon: "gearshape.fill",
                                title: "Configurações",
                                hasDisclosure: true
                            ) {
                                navigationManager.presentSheet(.settings)
                            }
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            ProfileOptionRow(
                                icon: "questionmark.circle.fill",
                                title: "Ajuda",
                                hasDisclosure: true
                            ) {
                                navigationManager.presentSheet(.help)
                            }
                            
                            Divider()
                                .padding(.leading, 44)
                            
                            ProfileOptionRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sair",
                                hasDisclosure: false,
                                textColor: DesignSystem.Colors.error
                            ) {
                                authManager.signOut()
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
        }
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let hasDisclosure: Bool
    let textColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        hasDisclosure: Bool = true,
        textColor: Color = DesignSystem.Colors.label,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.hasDisclosure = hasDisclosure
        self.textColor = textColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            DesignSystem.Haptics.light()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(textColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if hasDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modal Views
struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Premium",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Premium Features
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Text("Desbloqueie todo o potencial")
                            .font(DesignSystem.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.label)
                            .multilineTextAlignment(.center)
                        
                        Text("Análises avançadas com IA, insights personalizados e muito mais")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Features List
                    VStack(spacing: DesignSystem.Spacing.md) {
                        FeatureRow(icon: "infinity", title: "Entradas ilimitadas", description: "Escreva quantas vezes quiser")
                        FeatureRow(icon: "brain.head.profile", title: "Análises com IA", description: "Insights profundos sobre seus padrões")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Relatórios avançados", description: "Gráficos e estatísticas detalhadas")
                        FeatureRow(icon: "icloud.and.arrow.up", title: "Backup automático", description: "Seus dados sempre seguros")
                    }
                    
                    // CTA Button
                    Button("Começar teste grátis de 7 dias") {
                        // Handle subscription
                        DesignSystem.Haptics.medium()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Text("Cancele a qualquer momento")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Configurações",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            List {
                Section("Conta") {
                    ProfileOptionRow(
                        icon: "person.circle",
                        title: "Editar Perfil"
                    ) {
                        // Handle edit profile
                    }
                    
                    ProfileOptionRow(
                        icon: "lock.shield",
                        title: "Privacidade"
                    ) {
                        // Handle privacy settings
                    }
                }
                
                Section("App") {
                    ProfileOptionRow(
                        icon: "bell",
                        title: "Notificações"
                    ) {
                        // Handle notifications
                    }
                    
                    ProfileOptionRow(
                        icon: "moon",
                        title: "Modo Escuro"
                    ) {
                        // Handle dark mode
                    }
                }
                
                Section("Suporte") {
                    ProfileOptionRow(
                        icon: "questionmark.circle",
                        title: "Ajuda"
                    ) {
                        navigationManager.presentSheet(.help)
                    }
                    
                    ProfileOptionRow(
                        icon: "envelope",
                        title: "Contato"
                    ) {
                        // Handle contact
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct HelpView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Ajuda",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            List {
                Section("Perguntas Frequentes") {
                    ProfileOptionRow(
                        icon: "questionmark.circle",
                        title: "Como criar uma entrada no diário?"
                    ) {
                        // Handle FAQ
                    }
                    
                    ProfileOptionRow(
                        icon: "questionmark.circle",
                        title: "Como funciona a análise de IA?"
                    ) {
                        // Handle FAQ
                    }
                }
                
                Section("Contato") {
                    ProfileOptionRow(
                        icon: "envelope",
                        title: "Enviar Feedback"
                    ) {
                        // Handle feedback
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Placeholder Additional Views
struct SubscriptionPlansView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Planos",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            AppleEmptyStateView(
                icon: "crown.fill",
                title: "Planos Premium",
                description: "Escolha o plano que melhor se adequa às suas necessidades."
            )
        }
    }
}

struct AIAnalysisView: View {
    let diaryEntry: DiaryEntry?
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Análise de IA") {
            AppleEmptyStateView(
                icon: "brain.head.profile",
                title: "Análise em Desenvolvimento",
                description: "A análise com IA da sua entrada estará disponível em breve."
            )
        }
    }
}

struct PrivacyPolicyView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Política de Privacidade") {
            ScrollView {
                Text("Política de Privacidade em desenvolvimento...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .padding(DesignSystem.Spacing.lg)
            }
        }
    }
}

struct TermsOfServiceView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        AppleStyleNavigationView(title: "Termos de Serviço") {
            ScrollView {
                Text("Termos de Serviço em desenvolvimento...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .padding(DesignSystem.Spacing.lg)
            }
        }
    }
}