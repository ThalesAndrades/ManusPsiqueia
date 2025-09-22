//
//  SubscriptionView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var stripeManager: StripeManager
    
    @State private var selectedPlan: SubscriptionPlan = .psychologistMonthly
    @State private var showPaymentSheet = false
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var showFeatures = false
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedSubscriptionBackground(animateGradient: $animateGradient)
            
            // Floating particles
            SubscriptionParticlesView(offset: $particleOffset)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Hero section
                    heroSection
                    
                    // Plans section
                    plansSection
                    
                    // Features section
                    featuresSection
                    
                    // CTA section
                    ctaSection
                    
                    // Footer
                    footerSection
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showPaymentSheet) {
            PaymentSheetView(selectedPlan: selectedPlan)
                .environmentObject(stripeManager)
                .environmentObject(subscriptionManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo and title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manus Psiqueia")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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
                    
                    Text("Plataforma Premium")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Premium badge
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.3),
                            Color.orange.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
            }
            
            // Subtitle
            Text("Transforme sua prática psicológica com tecnologia de ponta")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Main icon with glow
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
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "stethoscope")
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
            
            // Hero text
            VStack(spacing: 16) {
                Text("Eleve sua prática ao próximo nível")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Acesse ferramentas avançadas de IA, gestão completa de pacientes e dashboard financeiro profissional")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var plansSection: some View {
        VStack(spacing: 20) {
            // Section title
            Text("Escolha seu plano")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            // Plans
            VStack(spacing: 16) {
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    SubscriptionPlanCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        pulseAnimation: pulseAnimation
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 24) {
            // Section title
            HStack {
                Text("Recursos inclusos")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showFeatures.toggle()
                    }
                }) {
                    Image(systemName: showFeatures ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if showFeatures {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(selectedPlan.features.indices, id: \.self) { index in
                        FeatureCard(
                            feature: selectedPlan.features[index],
                            index: index
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var ctaSection: some View {
        VStack(spacing: 20) {
            // Main CTA button
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showPaymentSheet = true
                }
            }) {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Assinar \(selectedPlan.displayName)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(selectedPlan.formattedPrice)/\(selectedPlan == .psychologistMonthly ? "mês" : "ano")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
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
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .shadow(
                    color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.5),
                    radius: 25,
                    x: 0,
                    y: 15
                )
            }
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: pulseAnimation
            )
            
            // Security badges
            HStack(spacing: 20) {
                SecurityBadge(icon: "lock.shield.fill", text: "Seguro")
                SecurityBadge(icon: "creditcard.fill", text: "Stripe")
                SecurityBadge(icon: "checkmark.seal.fill", text: "LGPD")
            }
            
            // Terms
            Text("Ao assinar, você concorda com nossos Termos de Uso e Política de Privacidade. Cancele a qualquer momento.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Support
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Precisa de ajuda? Entre em contato conosco")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Company info
            Text("AiLun Tecnologia • CNPJ: 60.740.536/0001-75")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animateGradient = true
            pulseAnimation = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showFeatures = true
        }
        
        // Start particle animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                particleOffset += 1
            }
        }
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let pulseAnimation: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: plan.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(plan.color)
                            
                            Text(plan.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(plan.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(plan.formattedPrice)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(plan.duration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Savings badge for yearly plan
                if let savings = plan.savings {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text(savings)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text("Equivale a \(plan.monthlyEquivalent)/mês")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Selection indicator
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? plan.color : .white.opacity(0.3))
                    
                    Text(isSelected ? "Plano selecionado" : "Selecionar plano")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? plan.color : .white.opacity(0.7))
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isSelected ? 0.15 : 0.05),
                                Color.white.opacity(isSelected ? 0.1 : 0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? plan.color.opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? plan.color.opacity(0.3) : Color.clear,
                radius: isSelected ? 20 : 0,
                x: 0,
                y: isSelected ? 10 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let feature: String
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
            
            Text(feature)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: index)
    }
}

// MARK: - Security Badge
struct SecurityBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Animated Background
struct AnimatedSubscriptionBackground: View {
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
            
            // Animated overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.15),
                    Color.clear,
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.15)
                ]),
                startPoint: animateGradient ? .topTrailing : .bottomLeading,
                endPoint: animateGradient ? .bottomLeading : .topTrailing
            )
            .animation(
                Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Subscription Particles
struct SubscriptionParticlesView: View {
    @Binding var offset: CGFloat
    @State private var particles: [SubscriptionParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(offset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(offset * particle.speed * 0.6) * particle.amplitude * 0.4
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
        particles = (0..<20).map { _ in
            SubscriptionParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...5),
                color: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.2),
                    Color.white.opacity(0.1)
                ].randomElement()!,
                speed: Double.random(in: 0.008...0.025),
                amplitude: CGFloat.random(in: 20...60),
                opacity: Double.random(in: 0.3...0.7),
                blur: CGFloat.random(in: 0...3)
            )
        }
    }
}

struct SubscriptionParticle: Identifiable {
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

// MARK: - Payment Sheet View
struct PaymentSheetView: View {
    let selectedPlan: SubscriptionPlan
    @EnvironmentObject var stripeManager: StripeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Pagamento - \(selectedPlan.displayName)")
                    .font(.title2)
                    .padding()
                
                Text("Implementar integração com Stripe Payment Sheet")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Pagamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(StripeManager())
}
