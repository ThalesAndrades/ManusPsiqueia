//
//  OnboardingView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    @State private var showUserTypeSelection = false
    @State private var animateGradient = false
    @State private var particleOffset: CGFloat = 0
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView(animateGradient: $animateGradient)
            
            // Floating particles
            FloatingParticlesView(offset: $particleOffset)
            
            VStack(spacing: 0) {
                // Top section with logo
                topSection
                
                // Main content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Página \(index + 1) de \(pages.count) do tutorial")
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(
                    AccessibilityConfiguration.shouldReduceAnimations ? .none : .easeInOut(duration: 0.6), 
                    value: currentPage
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tutorial do aplicativo")
                .accessibilityHint("Deslize para navegar entre as páginas do tutorial")
                .onChange(of: currentPage) { newPage in
                    AccessibilityUtils.announceStateChange("Página \(newPage + 1) de \(pages.count)")
                }
                
                // Bottom section with controls
                bottomSection
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showUserTypeSelection) {
            UserTypeSelectionView()
                .environmentObject(authManager)
        }
    }
    
    private var topSection: some View {
        VStack(spacing: 16) {
            // Logo with glow effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.4),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateGradient ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateGradient
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
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
            
            // App name
            VStack(spacing: 4) {
                Text("Manus")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Psiqueia")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
    
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Page indicators
            HStack(spacing: 12) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? 
                              Color(red: 0.4, green: 0.2, blue: 0.8) : 
                              Color.white.opacity(0.3))
                        .frame(width: currentPage == index ? 12 : 8, 
                               height: currentPage == index ? 12 : 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.bottom, 20)
            
            // Action buttons
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    // Get started button
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showUserTypeSelection = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Começar Jornada")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.8),
                                    Color(red: 0.2, green: 0.6, blue: 0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(
                            color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.4),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                    }
                    .scaleEffect(animateGradient ? 1.02 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animateGradient
                    )
                } else {
                    // Next button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Continuar")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.8),
                                    Color(red: 0.2, green: 0.6, blue: 0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(
                            color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    }
                }
                
                // Skip button
                if currentPage < pages.count - 1 {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showUserTypeSelection = true
                        }
                    }) {
                        Text("Pular Introdução")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 50)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animateGradient = true
        }
        
        // Start particle animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                particleOffset += 1
            }
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                page.color.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateContent
                    )
                
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(page.color)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateContent)
            }
            
            // Content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
                
                Text(page.description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
            }
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackgroundView: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay gradients
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.1),
                    Color.clear,
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.1)
                ]),
                startPoint: animateGradient ? .topTrailing : .bottomLeading,
                endPoint: animateGradient ? .bottomLeading : .topTrailing
            )
            .animation(
                Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            // Subtle mesh gradient overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.05),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .scaleEffect(animateGradient ? 1.2 : 0.8)
            .animation(
                Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Floating Particles
struct FloatingParticlesView: View {
    @Binding var offset: CGFloat
    @State private var particles: [FloatingParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(offset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(offset * particle.speed * 0.8) * particle.amplitude * 0.5
                        )
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<30).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...6),
                color: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.2),
                    Color.white.opacity(0.1)
                ].randomElement()!,
                speed: Double.random(in: 0.01...0.03),
                amplitude: CGFloat.random(in: 20...50),
                opacity: Double.random(in: 0.3...0.7),
                blur: CGFloat.random(in: 0...3)
            )
        }
    }
}

struct FloatingParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let speed: Double
    let amplitude: CGFloat
    let opacity: Double
    let blur: CGFloat
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    static let allPages = [
        OnboardingPage(
            title: "Inteligência Artificial em Saúde Mental",
            description: "Revolucione sua prática psicológica com IA avançada que oferece insights profundos e análises em tempo real para melhor cuidado dos pacientes.",
            icon: "brain.head.profile",
            color: Color(red: 0.4, green: 0.2, blue: 0.8)
        ),
        OnboardingPage(
            title: "Plataforma Completa para Psicólogos",
            description: "Gerencie pacientes, agende consultas, processe pagamentos e acesse relatórios detalhados em uma única plataforma integrada.",
            icon: "stethoscope",
            color: Color(red: 0.2, green: 0.6, blue: 0.9)
        ),
        OnboardingPage(
            title: "Pagamentos Seguros e Automáticos",
            description: "Sistema completo de pagamentos com Stripe, gestão financeira avançada e transferências automáticas para psicólogos.",
            icon: "creditcard.fill",
            color: Color(red: 0.9, green: 0.3, blue: 0.5)
        ),
        OnboardingPage(
            title: "Conecte-se com Cuidado",
            description: "Pacientes se conectam diretamente com psicólogos qualificados, criando vínculos terapêuticos duradouros e eficazes.",
            icon: "heart.text.square.fill",
            color: Color(red: 0.3, green: 0.8, blue: 0.4)
        )
    ]
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}
