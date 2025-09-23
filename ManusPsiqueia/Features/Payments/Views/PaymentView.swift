//
//  PaymentView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Stripe
import StripePaymentSheet

struct PaymentView: View {
    @StateObject private var stripeManager = StripeManager.shared
    @StateObject private var viewModel = PaymentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let patient: Patient
    let psychologist: Psychologist
    let amount: Decimal
    let description: String
    
    @State private var showingPaymentSheet = false
    @State private var showingPaymentMethods = false
    @State private var selectedPaymentMethod: StripePaymentMethod?
    @State private var savePaymentMethod = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    paymentHeader
                    
                    // Payment Details
                    paymentDetailsCard
                    
                    // Payment Methods
                    paymentMethodsSection
                    
                    // Payment Options
                    paymentOptionsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Pagamento")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupPayment()
        }
        .alert("Pagamento", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .paymentSheet(
            isPresented: $showingPaymentSheet,
            paymentSheet: stripeManager.paymentSheet
        ) { result in
            handlePaymentResult(result)
        }
    }
    
    // MARK: - Header
    private var paymentHeader: some View {
        VStack(spacing: 16) {
            // Patient Info
            HStack {
                AsyncImage(url: URL(string: patient.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Paciente")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Psychologist Info
            HStack {
                AsyncImage(url: URL(string: psychologist.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            Image(systemName: "stethoscope")
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(psychologist.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Psicólogo(a)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Payment Details
    private var paymentDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detalhes do Pagamento")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Descrição:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(description)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Valor:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(formatAmount(amount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Data:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Payment Methods
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Métodos de Pagamento")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Gerenciar") {
                    showingPaymentMethods = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if stripeManager.paymentMethods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Nenhum método de pagamento salvo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Adicione um cartão ou configure PIX para pagamentos mais rápidos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(stripeManager.paymentMethods) { method in
                        PaymentMethodRow(
                            paymentMethod: method,
                            isSelected: selectedPaymentMethod?.id == method.id
                        ) {
                            selectedPaymentMethod = method
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Payment Options
    private var paymentOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Opções")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Salvar método de pagamento", isOn: $savePaymentMethod)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Text("Seus dados de pagamento são protegidos com criptografia de nível bancário")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Pay Button
            Button(action: processPayment) {
                HStack {
                    if stripeManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard.fill")
                    }
                    
                    Text(stripeManager.isLoading ? "Processando..." : "Pagar \(formatAmount(amount))")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(stripeManager.isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(stripeManager.isLoading)
            
            // Alternative Payment Methods
            HStack(spacing: 12) {
                // PIX Button
                Button(action: payWithPIX) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("PIX")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                // Apple Pay Button (if available)
                if stripeManager.isApplePaySupported {
                    Button(action: payWithApplePay) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Pay")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    private func setupPayment() {
        Task {
            await viewModel.setupPayment(
                patientId: patient.id,
                psychologistId: psychologist.id,
                amount: amount,
                description: description
            )
        }
    }
    
    private func processPayment() {
        guard let paymentIntent = viewModel.paymentIntent else {
            alertMessage = "Erro ao configurar pagamento. Tente novamente."
            showingAlert = true
            return
        }
        
        Task {
            do {
                try await stripeManager.presentPaymentSheet(
                    paymentIntentClientSecret: paymentIntent.clientSecret,
                    customerId: paymentIntent.customerId
                )
                showingPaymentSheet = true
            } catch {
                alertMessage = "Erro ao processar pagamento: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func payWithPIX() {
        Task {
            do {
                let pixPayment = try await stripeManager.createPIXPayment(
                    amount: Int(amount * 100), // Convert to cents
                    customerId: patient.id.uuidString,
                    description: description
                )
                
                // Navigate to PIX QR Code view
                // Implementation depends on your navigation structure
                
            } catch {
                alertMessage = "Erro ao gerar PIX: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func payWithApplePay() {
        Task {
            do {
                try await stripeManager.presentApplePay(
                    amount: amount,
                    description: description
                )
            } catch {
                alertMessage = "Erro no Apple Pay: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            alertMessage = "Pagamento realizado com sucesso!"
            showingAlert = true
            
            // Update payment status
            Task {
                await viewModel.updatePaymentStatus(.succeeded)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
            
        case .canceled:
            alertMessage = "Pagamento cancelado"
            showingAlert = true
            
        case .failed(let error):
            alertMessage = "Falha no pagamento: \(error.localizedDescription)"
            showingAlert = true
            
            Task {
                await viewModel.updatePaymentStatus(.failed)
            }
        }
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let paymentMethod: StripePaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Payment Method Icon
                Image(systemName: paymentMethod.type.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(paymentMethod.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if paymentMethod.isDefault {
                        Text("Padrão")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let card = paymentMethod.card, card.isExpired {
                        Text("Expirado")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
