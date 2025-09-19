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
    @State private var showSplashScreen = true
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showSplashScreen {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Mostrar splash screen por 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplashScreen = false
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if authManager.isAuthenticated {
            if let user = authManager.currentUser {
                switch user.userType {
                case .psychologist:
                    if subscriptionManager.hasActiveSubscription {
                        PsychologistDashboardView()
                    } else {
                        SubscriptionView()
                    }
                case .patient:
                    PatientDashboardView()
                }
            } else {
                LoadingView()
            }
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var particlesOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Animated particles background
            ParticlesView()
                .opacity(particlesOpacity)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo principal
                VStack(spacing: 20) {
                    // Ícone do app com efeito de glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8),
                                        Color(red: 0.2, green: 0.6, blue: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Nome do app
                    VStack(spacing: 8) {
                        Text("Manus")
                            .font(.system(size: 42, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Psiqueia")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8),
                                        Color(red: 0.2, green: 0.6, blue: 0.9)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .opacity(textOpacity)
                }
                
                Spacer()
                
                // Tagline
                VStack(spacing: 12) {
                    Text("Inteligência Artificial")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("em Saúde Mental")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color(red: 0.4, green: 0.2, blue: 0.8))
                                .frame(width: 8, height: 8)
                                .scaleEffect(logoScale)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: logoScale
                                )
                        }
                    }
                    .padding(.top, 20)
                }
                .opacity(textOpacity)
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                particlesOpacity = 1.0
            }
        }
    }
}

// MARK: - Particles Animation
struct ParticlesView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    private func generateParticles() {
        particles = (0..<50).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 1...4),
                color: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.6),
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.4),
                    Color.white.opacity(0.3)
                ].randomElement()!,
                opacity: Double.random(in: 0.2...0.8),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                for index in particles.indices {
                    particles[index].position.x += CGFloat.random(in: -1...1)
                    particles[index].position.y += CGFloat.random(in: -1...1)
                    particles[index].opacity = Double.random(in: 0.1...0.8)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    let blur: CGFloat
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading spinner
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.8),
                            Color(red: 0.2, green: 0.6, blue: 0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            Text("Carregando...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(StripeManager())
}
