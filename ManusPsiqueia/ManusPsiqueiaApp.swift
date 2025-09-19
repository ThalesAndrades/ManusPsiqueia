//
//  ManusPsiqueiaApp.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import StoreKit

@main
struct ManusPsiqueiaApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var stripeManager = StripeManager()
    
    init() {
        setupAppearance()
        configureStoreKit()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(stripeManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    Task {
                        await authManager.checkAuthenticationState()
                        await subscriptionManager.loadSubscriptions()
                    }
                }
                .task {
                    // Configurar listeners para transações do StoreKit
                    await subscriptionManager.listenForTransactions()
                }
        }
    }
    
    private func setupAppearance() {
        // Configurar aparência global do app
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configurar tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configurar cores globais
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0)
    }
    
    private func configureStoreKit() {
        // Configurar StoreKit para assinaturas
        SKPaymentQueue.default().add(subscriptionManager)
    }
}

// MARK: - App Configuration
extension ManusPsiqueiaApp {
    struct AppConfig {
        static let primaryColor = Color(red: 0.4, green: 0.2, blue: 0.8)
        static let secondaryColor = Color(red: 0.2, green: 0.6, blue: 0.9)
        static let accentColor = Color(red: 0.9, green: 0.3, blue: 0.5)
        static let backgroundColor = Color.black
        static let surfaceColor = Color(red: 0.1, green: 0.1, blue: 0.1)
        
        // Preços das assinaturas
        static let psychologistSubscriptionPrice: Decimal = 89.90
        static let patientConsultationBasePrice: Decimal = 150.00
        
        // Configurações do Stripe
        static let stripePublishableKey = "pk_test_..." // Será configurado via environment
        static let stripeSecretKey = "sk_test_..." // Será configurado via environment
        
        // URLs da API
        static let baseAPIURL = "https://api.manuspsiqueia.com"
        static let supabaseURL = "https://your-project.supabase.co"
        static let supabaseAnonKey = "your-anon-key"
    }
}

// MARK: - Environment Keys
struct AuthenticationManagerKey: EnvironmentKey {
    static let defaultValue = AuthenticationManager()
}

struct SubscriptionManagerKey: EnvironmentKey {
    static let defaultValue = SubscriptionManager()
}

struct StripeManagerKey: EnvironmentKey {
    static let defaultValue = StripeManager()
}

extension EnvironmentValues {
    var authManager: AuthenticationManager {
        get { self[AuthenticationManagerKey.self] }
        set { self[AuthenticationManagerKey.self] = newValue }
    }
    
    var subscriptionManager: SubscriptionManager {
        get { self[SubscriptionManagerKey.self] }
        set { self[SubscriptionManagerKey.self] = newValue }
    }
    
    var stripeManager: StripeManager {
        get { self[StripeManagerKey.self] }
        set { self[StripeManagerKey.self] = newValue }
    }
}
