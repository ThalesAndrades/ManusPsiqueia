//
//  PaymentSheetView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import StripePaymentSheet

struct PaymentSheetView: View {
    @StateObject private var stripeManager = StripePaymentSheetManager.shared
    @State private var showingPaymentSheet = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    
    let paymentType: PaymentType
    let amount: Int
    let userId: String
    let onCompletion: (PaymentSheetResult) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: paymentType.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(paymentType.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(paymentType.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            
            // Amount Display
            VStack(spacing: 8) {
                Text("Valor")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(stripeManager.formatCurrency(amount))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            
            // Payment Features
            VStack(alignment: .leading, spacing: 16) {
                PaymentFeatureRow(
                    icon: "creditcard.fill",
                    title: "Pagamento Seguro",
                    description: "Criptografia de nível bancário"
                )
                
                PaymentFeatureRow(
                    icon: "checkmark.shield.fill",
                    title: "Proteção Total",
                    description: "Seus dados estão protegidos"
                )
                
                PaymentFeatureRow(
                    icon: "clock.fill",
                    title: "Processamento Rápido",
                    description: "Confirmação instantânea"
                )
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            // Payment Button
            Button(action: {
                Task {
                    await prepareAndShowPaymentSheet()
                }
            }) {
                HStack {
                    if stripeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard")
                        Text("Pagar com Cartão")
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
            .paymentSheet(
                isPresented: $showingPaymentSheet,
                paymentSheet: stripeManager.backendModel.paymentSheet
            ) { result in
                handlePaymentResult(result)
            }
            
            // Apple Pay Button (if available)
            if PaymentSheet.isApplePaySupported {
                Button(action: {
                    // Handle Apple Pay
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Pagar com Apple Pay")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            // Security Notice
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Pagamento processado com segurança pelo Stripe")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .alert("Pagamento Realizado", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Seu pagamento foi processado com sucesso!")
        }
        .alert("Erro no Pagamento", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(stripeManager.errorMessage ?? "Ocorreu um erro inesperado")
        }
        .onChange(of: stripeManager.errorMessage) { errorMessage in
            if errorMessage != nil {
                showingErrorAlert = true
            }
        }
    }
    
    private func prepareAndShowPaymentSheet() async {
        do {
            switch paymentType {
            case .subscription:
                _ = try await stripeManager.createPsychologistSubscription(
                    userId: userId,
                    email: "user@example.com" // This should come from user data
                )
            case .therapy:
                _ = try await stripeManager.processPatientPayment(
                    amount: amount,
                    patientId: userId,
                    psychologistId: "psychologist_id" // This should come from context
                )
            }
            
            if stripeManager.presentPaymentSheet() {
                showingPaymentSheet = true
            }
        } catch {
            stripeManager.errorMessage = error.localizedDescription
        }
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        stripeManager.handlePaymentResult(result)
        onCompletion(result)
        
        switch result {
        case .completed:
            showingSuccessAlert = true
        case .canceled:
            break // User canceled, no action needed
        case .failed(_):
            showingErrorAlert = true
        }
    }
}

struct PaymentFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

enum PaymentType {
    case subscription
    case therapy
    
    var title: String {
        switch self {
        case .subscription:
            return "Assinatura Psicólogo"
        case .therapy:
            return "Pagamento de Consulta"
        }
    }
    
    var description: String {
        switch self {
        case .subscription:
            return "Acesso completo à plataforma ManusPsiqueia"
        case .therapy:
            return "Pagamento seguro para sua sessão de terapia"
        }
    }
    
    var icon: String {
        switch self {
        case .subscription:
            return "person.badge.plus"
        case .therapy:
            return "heart.text.square"
        }
    }
}

// MARK: - Preview
struct PaymentSheetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PaymentSheetView(
                paymentType: .subscription,
                amount: 8990,
                userId: "user_123"
            ) { result in
                print("Payment result: \(result)")
            }
        }
    }
}
