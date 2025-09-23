import ManusPsiqueiaCore
//
//  UserTypeSelectionView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct UserTypeSelectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserType: UserType?
    @State private var showRegistration = false
    @State private var animateCards = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background
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
            
            // Floating particles background
            FloatingParticlesBackground()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Title section
                        titleSection
                        
                        // User type cards
                        userTypeCards
                        
                        // Continue button
                        continueButton
                        
                        // Login option
                        loginSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showRegistration) {
            if let userType = selectedUserType {
                RegistrationView(userType: userType)
                    .environmentObject(authManager)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            // Icon
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
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40, weight: .light))
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
            
            // Title and description
            VStack(spacing: 12) {
                Text("Como você gostaria de usar o Manus Psiqueia?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Escolha o tipo de conta que melhor se adequa ao seu perfil")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
    }
    
    private var userTypeCards: some View {
        VStack(spacing: 20) {
            ForEach(UserType.allCases, id: \.self) { userType in
                UserTypeCard(
                    userType: userType,
                    isSelected: selectedUserType == userType,
                    animateCards: animateCards
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedUserType = userType
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var continueButton: some View {
        Button(action: {
            guard selectedUserType != nil else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showRegistration = true
            }
        }) {
            HStack(spacing: 12) {
                Text("Continuar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if selectedUserType != nil {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                Color(red: 0.2, green: 0.6, blue: 0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(
                color: selectedUserType != nil ? 
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.4) : 
                    Color.clear,
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .disabled(selectedUserType == nil)
        .scaleEffect(selectedUserType != nil && pulseAnimation ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: pulseAnimation
        )
        .padding(.top, 32)
    }
    
    private var loginSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                Text("ou")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            }
            
            // Login button
            Button(action: {
                // Implementar navegação para login
                print("Navegar para login")
            }) {
                Text("Já tenho uma conta")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .underline()
            }
        }
        .padding(.top, 24)
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateCards = true
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            pulseAnimation = true
        }
    }
}

// MARK: - User Type Card
public struct UserTypeCard: View {
    let userType: UserType
    let isSelected: Bool
    let animateCards: Bool
    let onTap: () -> Void
    
    @State private var cardScale: CGFloat = 0.9
    @State private var cardOpacity: Double = 0.0
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                // Icon section
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    userType.color.opacity(isSelected ? 0.3 : 0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: userType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(userType.color)
                }
                
                // Content section
                VStack(spacing: 12) {
                    Text(userType.displayName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(userType.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    // Features for psychologist
                    if userType == .psychologist {
                        VStack(spacing: 8) {
                            FeatureRow(icon: "dollarsign.circle.fill", text: "Assinatura R$ 89,90/mês")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Dashboard financeiro completo")
                            FeatureRow(icon: "person.3.fill", text: "Gestão ilimitada de pacientes")
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 8) {
                            FeatureRow(icon: "checkmark.circle.fill", text: "Acesso gratuito à plataforma")
                            FeatureRow(icon: "link", text: "Vinculação com psicólogo")
                            FeatureRow(icon: "message.fill", text: "Chat seguro e privado")
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
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
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? 
                                    userType.color.opacity(0.6) : 
                                    Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? userType.color.opacity(0.3) : Color.clear,
                radius: isSelected ? 20 : 0,
                x: 0,
                y: isSelected ? 10 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(userType == .psychologist ? 0.1 : 0.3)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }
}

// MARK: - Feature Row
public struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Floating Particles Background
public struct FloatingParticlesBackground: View {
    @State private var animationOffset: CGFloat = 0
    @State private var particles: [BackgroundParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(animationOffset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(animationOffset * particle.speed * 0.7) * particle.amplitude * 0.3
                        )
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
        particles = (0..<25).map { _ in
            BackgroundParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 1...4),
                color: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.2),
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.15),
                    Color.white.opacity(0.1)
                ].randomElement()!,
                speed: Double.random(in: 0.005...0.02),
                amplitude: CGFloat.random(in: 15...40),
                opacity: Double.random(in: 0.2...0.6),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                animationOffset += 1
            }
        }
    }
}

public struct BackgroundParticle: Identifiable {
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

#Preview {
    UserTypeSelectionView()
        .environmentObject(AuthenticationManager())
}
