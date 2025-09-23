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
    @StateObject private var flowManager = FlowManager.shared
    @State private var showOnboarding: Bool = true
    @State private var showSplashScreen: Bool = true

    var body: some View {
        ZStack {
            if showSplashScreen {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                Group {
                    if authManager.isAuthenticated {
                        // Decide which dashboard to show based on user type
                        if authManager.currentUser?.userType == .psychologist {
                            PsychologistDashboardView()
                        } else if authManager.currentUser?.userType == .patient {
                            PatientDashboardView()
                        } else {
                            // Fallback or loading state if user type is not immediately available
                            LoadingView()
                        }
                    } else {
                        AuthenticationView()
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            // Simulate app launch time or data loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplashScreen = false
                }
            }
            // Check if onboarding has been shown before
            showOnboarding = !UserDefaults.standard.bool(forKey: "hasShownOnboarding")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
        }
        .fullScreenCover(isPresented: $flowManager.showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $flowManager.showOnboarding) {
            OnboardingView(showOnboarding: $flowManager.showOnboarding)
        }
        .onOpenURL { url in
            flowManager.handleDeepLink(url)
        }
        .environmentObject(flowManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager())
            .environmentObject(SubscriptionManager())
            .environmentObject(StripePaymentSheetManager())
    }
}

// Moving SplashScreenView, ParticlesView, Particle, and LoadingView to separate files
// to keep ContentView focused on navigation logic and improve readability/maintainability.

