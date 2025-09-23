import ManusPsiqueiaCore
//
//  SubscriptionViewWithStripe.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import StripePaymentSheet

public struct SubscriptionViewWithStripe: View {
    @StateObject private var stripeManager = StripePaymentSheetManager.shared
    @State private var showingPaymentSheet = false
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showingSuccess = false
    @State private var animateGradient = false
    
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header with animated background
                headerSection
                
                // Subscription plans
                plansSection
                
                // Features list
                featuresSection
                
                // Payment button
                paymentSection
                
                // Terms and conditions
                termsSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1),
                    Color.clear
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
        )
        .navigationTitle("Assinatura Premium")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            animateGradient = true
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSheetView(
                paymentType: .subscription,
                amount: selectedPlan.priceInCents,
                userId: user.id.uuidString
            ) { result in
                handlePaymentResult(result)
            }
        }
        .alert("Assinatura Ativada!", isPresented: $showingSuccess) {
            Button("Continuar") {
                // Navigate to dashboard or dismiss
            }
        } message: {
            Text("Bem-vindo à comunidade premium ManusPsiqueia! Sua assinatura está ativa.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Torne-se um Psicólogo")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Premium na ManusPsiqueia")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Acesse todas as funcionalidades profissionais e comece a atender pacientes hoje mesmo")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("Escolha seu Plano")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                SubscriptionPlanCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    onSelect: { selectedPlan = .monthly }
                )
                
                SubscriptionPlanCard(
                    plan: .annual,
                    isSelected: selectedPlan == .annual,
                    onSelect: { selectedPlan = .annual }
                )
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("O que está incluído")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "person.2.fill",
                    title: "Pacientes Ilimitados",
                    description: "Atenda quantos pacientes quiser"
                )
                
                FeatureCard(
                    icon: "calendar",
                    title: "Agendamento",
                    description: "Sistema completo de agendas"
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Analytics Avançado",
                    description: "Relatórios detalhados de progresso"
                )
                
                FeatureCard(
                    icon: "brain.head.profile",
                    title: "IA Terapêutica",
                    description: "Insights baseados em IA"
                )
                
                FeatureCard(
                    icon: "creditcard.fill",
                    title: "Pagamentos",
                    description: "Receba pagamentos automaticamente"
                )
                
                FeatureCard(
                    icon: "shield.checkered",
                    title: "Segurança Total",
                    description: "Compliance LGPD e HIPAA"
                )
            }
        }
    }
    
    private var paymentSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingPaymentSheet = true
            }) {
                HStack {
                    if stripeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard.fill")
                        Text("Assinar por \(selectedPlan.displayPrice)")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(stripeManager.isLoading)
            
            // Payment methods
            HStack(spacing: 16) {
                Image("visa-logo") // Add these images to your assets
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                
                Image("mastercard-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                
                Image("apple-pay-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                
                Text("e mais")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
    }
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Pagamento 100% seguro processado pelo Stripe")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Ao continuar, você concorda com nossos [Termos de Uso](https://manuspsiqueia.com/terms) e [Política de Privacidade](https://manuspsiqueia.com/privacy)")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Cancele a qualquer momento. Sem taxas de cancelamento.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            showingSuccess = true
            // Update user subscription status
            // Navigate to dashboard
        case .canceled:
            // User canceled, no action needed
            break
        case .failed(let error):
            // Handle error
            print("Payment failed: \(error)")
        }
    }
}

public struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                if plan == .annual {
                    Text("MAIS POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                
                Text(plan.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(plan.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(plan.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if plan == .annual {
                    Text("Economize R$ 179,80")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.purple : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

public enum SubscriptionPlan: CaseIterable {
    case monthly
    case annual
    
    var title: String {
        switch self {
        case .monthly: return "Mensal"
        case .annual: return "Anual"
        }
    }
    
    var displayPrice: String {
        switch self {
        case .monthly: return "R$ 89,90/mês"
        case .annual: return "R$ 74,90/mês"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return "Cobrança mensal"
        case .annual: return "R$ 898,80 cobrados anualmente"
        }
    }
    
    var priceInCents: Int {
        switch self {
        case .monthly: return 8990 // R$ 89,90
        case .annual: return 89880 // R$ 898,80
        }
    }
}

// MARK: - Preview
public struct SubscriptionViewWithStripe_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubscriptionViewWithStripe(
                user: User(
                    id: UUID(),
                    email: "test@example.com",
                    fullName: "Dr. João Silva",
                    userType: .psychologist,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
        }
    }
}
