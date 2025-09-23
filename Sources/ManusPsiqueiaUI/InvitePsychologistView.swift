import ManusPsiqueiaCore
//
//  InvitePsychologistView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct InvitePsychologistView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var invitationManager: InvitationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var psychologistEmail = ""
    @State private var psychologistName = ""
    @State private var personalMessage = ""
    @State private var showingConfirmation = false
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var particleOffset: CGFloat = 0
    
    private let maxMessageLength = 500
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedInviteBackground(animateGradient: $animateGradient)
            
            // Floating particles
            InviteParticlesView(offset: $particleOffset)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Hero section
                    heroSection
                    
                    // Form section
                    formSection
                    
                    // Benefits section
                    benefitsSection
                    
                    // Action section
                    actionSection
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .alert("Convite Enviado!", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Seu convite foi enviado com sucesso! O psicólogo receberá um email com todas as informações para se juntar à plataforma.")
        }
        .alert("Erro", isPresented: .constant(invitationManager.errorMessage != nil)) {
            Button("OK") {
                invitationManager.clearMessages()
            }
        } message: {
            if let errorMessage = invitationManager.errorMessage {
                Text(errorMessage)
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
            
            Text("Convidar Psicólogo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
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
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "person.badge.plus.fill")
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
            
            // Hero text
            VStack(spacing: 16) {
                Text("Convide seu psicólogo preferido")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Envie um convite para que seu psicólogo se junte ao Manus Psiqueia e vocês possam ter sessões digitais seguras")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 40)
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Section title
            HStack {
                Text("Informações do Psicólogo")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Email do Psicólogo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("*")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    TextField("exemplo@email.com", text: $psychologistEmail)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Name field (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Nome do Psicólogo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("(opcional)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    TextField("Dr(a). Nome Sobrenome", text: $psychologistName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.name)
                }
                
                // Personal message field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Mensagem Pessoal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("(opcional)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(personalMessage.count)/\(maxMessageLength)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(personalMessage.count > maxMessageLength ? .red : .white.opacity(0.6))
                    }
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .frame(height: 100)
                        
                        TextEditor(text: $personalMessage)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .background(Color.clear)
                            .padding(12)
                            .onChange(of: personalMessage) { newValue in
                                if newValue.count > maxMessageLength {
                                    personalMessage = String(newValue.prefix(maxMessageLength))
                                }
                            }
                        
                        if personalMessage.isEmpty {
                            Text("Escreva uma mensagem personalizada para seu psicólogo...")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 20) {
            // Section title
            HStack {
                Text("O que seu psicólogo receberá")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                BenefitRow(
                    icon: "crown.fill",
                    title: "Plataforma Premium",
                    description: "Acesso completo por R$ 89,90/mês",
                    color: .yellow
                )
                
                BenefitRow(
                    icon: "brain.head.profile",
                    title: "IA Avançada",
                    description: "Ferramentas de inteligência artificial",
                    color: Color(red: 0.4, green: 0.2, blue: 0.8)
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Dashboard Financeiro",
                    description: "Gestão completa de pagamentos",
                    color: .green
                )
                
                BenefitRow(
                    icon: "shield.checkered",
                    title: "Segurança Total",
                    description: "Dados protegidos e criptografados",
                    color: .blue
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private var actionSection: some View {
        VStack(spacing: 20) {
            // Main CTA button
            Button(action: {
                sendInvitation()
            }) {
                HStack(spacing: 12) {
                    if invitationManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    Text(invitationManager.isLoading ? "Enviando..." : "Enviar Convite")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if isFormValid && !invitationManager.isLoading {
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
                    color: isFormValid && !invitationManager.isLoading ? 
                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.4) : 
                        Color.clear,
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .disabled(!isFormValid || invitationManager.isLoading)
            .scaleEffect(isFormValid && pulseAnimation ? 1.02 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: pulseAnimation
            )
            
            // Info text
            Text("O convite expira em 7 dias. Seu psicólogo receberá um email com todas as instruções para se cadastrar na plataforma.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 60)
    }
    
    private var isFormValid: Bool {
        return !psychologistEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(psychologistEmail)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendInvitation() {
        guard let currentUser = authManager.currentUser else { return }
        
        Task {
            do {
                let _ = try await invitationManager.sendInvitation(
                    toPsychologistEmail: psychologistEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                    toPsychologistName: psychologistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : psychologistName.trimmingCharacters(in: .whitespacesAndNewlines),
                    message: personalMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : personalMessage.trimmingCharacters(in: .whitespacesAndNewlines),
                    fromPatient: currentUser
                )
                
                DispatchQueue.main.async {
                    self.showingConfirmation = true
                }
            } catch {
                // Error is handled by the InvitationManager
                print("Erro ao enviar convite: \(error)")
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animateGradient = true
            pulseAnimation = true
        }
        
        // Start particle animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                particleOffset += 1
            }
        }
    }
}

// MARK: - Custom Text Field Style
public struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Benefit Row
public struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
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
    }
}

// MARK: - Animated Background
public struct AnimatedInviteBackground: View {
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
        }
        .ignoresSafeArea()
    }
}

// MARK: - Invite Particles
public struct InviteParticlesView: View {
    @Binding var offset: CGFloat
    @State private var particles: [InviteParticle] = []
    
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
        particles = (0..<25).map { _ in
            InviteParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...5),
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

public struct InviteParticle: Identifiable {
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
    InvitePsychologistView()
        .environmentObject(AuthenticationManager())
        .environmentObject(InvitationManager())
}
