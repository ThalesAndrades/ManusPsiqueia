//
//  ContentView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var alertManager = AlertManager()
    
    @State private var showSplashScreen: Bool = true
    @State private var hasCompletedOnboarding: Bool = false
    
    // App state tracking for better UX
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasShownOnboarding") private var hasShownOnboarding: Bool = false
    @AppStorage("userPreferredColorScheme") private var userPreferredColorScheme: String = "system"

    var body: some View {
        ZStack {
            // Background that adapts to color scheme
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            if showSplashScreen {
                AppleSplashScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            } else {
                mainContent
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(colorScheme)
        .environmentObject(navigationManager)
        .alertManager(alertManager)
        .onAppear {
            setupInitialState()
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhaseChange(phase)
        }
        .onOpenURL { url in
            navigationManager.handleDeepLink(url)
        }
        // Full screen covers for key flows
        .fullScreenCover(
            item: $navigationManager.presentedFullScreenCover
        ) { destination in
            fullScreenCoverContent(for: destination)
        }
        // Sheets for secondary flows
        .sheet(
            item: $navigationManager.presentedSheet
        ) { destination in
            sheetContent(for: destination)
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if !hasShownOnboarding {
            // First time user experience
            AppleOnboardingFlow()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        } else if authManager.isAuthenticated {
            // Authenticated user flow
            authenticatedUserContent
        } else {
            // Authentication required
            AppleAuthenticationView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        }
    }
    
    @ViewBuilder
    private var authenticatedUserContent: some View {
        if let userType = authManager.currentUser?.userType {
            switch userType {
            case .psychologist:
                PsychologistMainView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(navigationManager)
            case .patient:
                PatientMainView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(navigationManager)
            }
        } else {
            // Loading state while determining user type
            AppleLoadingView(message: "Carregando seu perfil...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignSystem.Colors.background)
        }
    }
    
    // MARK: - Sheet Content
    @ViewBuilder
    private func sheetContent(for destination: NavigationManager.SheetDestination) -> some View {
        switch destination {
        case .userTypeSelection:
            UserTypeSelectionView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .paywall:
            PaywallView()
                .environmentObject(subscriptionManager)
                .environmentObject(navigationManager)
        case .settings:
            SettingsView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .profile:
            ProfileView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .newDiaryEntry:
            NewDiaryEntryView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .subscriptionPlans:
            SubscriptionPlansView()
                .environmentObject(subscriptionManager)
                .environmentObject(navigationManager)
        case .help:
            HelpView()
                .environmentObject(navigationManager)
        }
    }
    
    // MARK: - Full Screen Cover Content
    @ViewBuilder
    private func fullScreenCoverContent(for destination: NavigationManager.FullScreenDestination) -> some View {
        switch destination {
        case .onboarding:
            AppleOnboardingFlow()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .authentication:
            AppleAuthenticationView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .subscription:
            SubscriptionView()
                .environmentObject(subscriptionManager)
                .environmentObject(navigationManager)
        }
    }
    
    // MARK: - Color Scheme
    private var colorScheme: ColorScheme? {
        switch userPreferredColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
    
    // MARK: - Setup Methods
    private func setupInitialState() {
        // Setup app appearance
        configureAppAppearance()
        
        // Restore navigation state if needed
        navigationManager.restoreNavigationState()
        
        // Check authentication state
        Task {
            await authManager.checkAuthenticationState()
            await subscriptionManager.loadSubscriptions()
            
            // Show splash screen for minimum duration for better UX
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                withAnimation(DesignSystem.Animation.easeInOut) {
                    showSplashScreen = false
                }
            }
        }
    }
    
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.label)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.label)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            Task {
                await authManager.refreshAuthenticationState()
            }
        case .inactive:
            // App became inactive
            navigationManager.saveNavigationState()
        case .background:
            // App went to background
            // Clear sensitive data if needed
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Apple HIG Compliant Splash Screen
struct AppleSplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.secondaryBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(backgroundOpacity)
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // App icon with subtle animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.primary.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 4) {
                    Text("Manus")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.light)
                        .foregroundColor(DesignSystem.Colors.label)
                    
                    Text("Psiqueia")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.secondary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.easeOut.delay(0.2)) {
                backgroundOpacity = 1.0
            }
            
            withAnimation(DesignSystem.Animation.spring.delay(0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        .accessibilityLabel("ManusPsiqueia - Carregando aplicativo")
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager())
            .environmentObject(SubscriptionManager())
            .environmentObject(StripeManager.shared)
    }
}

