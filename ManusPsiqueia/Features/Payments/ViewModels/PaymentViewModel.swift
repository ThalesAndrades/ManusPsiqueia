import ManusPsiqueiaServices
//
//  PaymentViewModel.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var paymentIntent: PaymentIntent?
    @Published var currentPayment: PatientPayment?
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let stripeManager = StripeManager.shared
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe Stripe manager loading state
        stripeManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Payment Setup
    func setupPayment(
        patientId: UUID,
        psychologistId: UUID,
        amount: Decimal,
        description: String,
        billingPeriod: BillingPeriod = .oneTime
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create customer if needed
            let customerId = try await stripeManager.getOrCreateCustomer(
                userId: patientId.uuidString,
                email: "", // Get from patient data
                name: "" // Get from patient data
            )
            
            // Create payment intent
            let paymentIntentResponse = try await stripeManager.createPaymentIntent(
                amount: Int(amount * 100), // Convert to cents
                currency: "brl",
                customerId: customerId,
                description: description,
                metadata: [
                    "patient_id": patientId.uuidString,
                    "psychologist_id": psychologistId.uuidString,
                    "billing_period": billingPeriod.rawValue
                ]
            )
            
            self.paymentIntent = paymentIntentResponse
            
            // Create local payment record
            let payment = PatientPayment(
                patientId: patientId,
                psychologistId: psychologistId,
                amount: amount,
                status: .pending,
                paymentMethodType: .card,
                billingPeriod: billingPeriod,
                dueDate: Date(),
                description: description,
                stripePaymentIntentId: paymentIntentResponse.id,
                stripeCustomerId: customerId
            )
            
            self.currentPayment = payment
            
            // Save to database
            try await savePaymentToDatabase(payment)
            
        } catch {
            self.errorMessage = "Erro ao configurar pagamento: \(error.localizedDescription)"
            self.showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Payment Processing
    func processPayment(with paymentMethodId: String) async -> Bool {
        guard let paymentIntent = paymentIntent else {
            errorMessage = "Payment intent não encontrado"
            showError = true
            return false
        }
        
        isLoading = true
        
        do {
            let confirmedIntent = try await stripeManager.confirmPaymentIntent(
                paymentIntentId: paymentIntent.id,
                paymentMethodId: paymentMethodId
            )
            
            // Update payment status based on result
            let newStatus: PaymentStatus = confirmedIntent.status == .succeeded ? .succeeded : .failed
            await updatePaymentStatus(newStatus)
            
            return newStatus == .succeeded
            
        } catch {
            errorMessage = "Erro ao processar pagamento: \(error.localizedDescription)"
            showError = true
            await updatePaymentStatus(.failed)
            return false
        }
    }
    
    // MARK: - Payment Status Updates
    func updatePaymentStatus(_ status: PaymentStatus) async {
        guard var payment = currentPayment else { return }
        
        payment = PatientPayment(
            id: payment.id,
            patientId: payment.patientId,
            psychologistId: payment.psychologistId,
            amount: payment.amount,
            currency: payment.currency,
            status: status,
            paymentMethodType: payment.paymentMethodType,
            billingPeriod: payment.billingPeriod,
            dueDate: payment.dueDate,
            paidDate: status == .succeeded ? Date() : nil,
            description: payment.description,
            stripePaymentIntentId: payment.stripePaymentIntentId,
            stripeChargeId: payment.stripeChargeId,
            stripeCustomerId: payment.stripeCustomerId,
            stripeSubscriptionId: payment.stripeSubscriptionId,
            invoiceNumber: payment.invoiceNumber,
            invoiceURL: payment.invoiceURL,
            receiptURL: payment.receiptURL,
            failureReason: status == .failed ? errorMessage : nil,
            metadata: payment.metadata,
            createdAt: payment.createdAt,
            updatedAt: Date()
        )
        
        self.currentPayment = payment
        
        do {
            try await updatePaymentInDatabase(payment)
        } catch {
            print("Erro ao atualizar pagamento no banco: \(error)")
        }
    }
    
    // MARK: - PIX Payment
    func createPIXPayment(
        patientId: UUID,
        psychologistId: UUID,
        amount: Decimal,
        description: String
    ) async -> PaymentIntent? {
        isLoading = true
        
        do {
            let customerId = try await stripeManager.getOrCreateCustomer(
                userId: patientId.uuidString,
                email: "",
                name: ""
            )
            
            let pixIntent = try await stripeManager.createPIXPayment(
                amount: Int(amount * 100),
                customerId: customerId,
                description: description
            )
            
            // Create local payment record
            let payment = PatientPayment(
                patientId: patientId,
                psychologistId: psychologistId,
                amount: amount,
                status: .pending,
                paymentMethodType: .pix,
                billingPeriod: .oneTime,
                dueDate: Date(),
                description: description,
                stripePaymentIntentId: pixIntent.id,
                stripeCustomerId: customerId
            )
            
            self.currentPayment = payment
            try await savePaymentToDatabase(payment)
            
            isLoading = false
            return pixIntent
            
        } catch {
            errorMessage = "Erro ao criar pagamento PIX: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Subscription Management
    func createSubscription(
        patientId: UUID,
        psychologistId: UUID,
        priceId: String,
        billingPeriod: BillingPeriod
    ) async -> StripeSubscription? {
        isLoading = true
        
        do {
            let customerId = try await stripeManager.getOrCreateCustomer(
                userId: patientId.uuidString,
                email: "",
                name: ""
            )
            
            let subscription = try await stripeManager.createSubscription(
                customerId: customerId,
                priceId: priceId,
                metadata: [
                    "patient_id": patientId.uuidString,
                    "psychologist_id": psychologistId.uuidString,
                    "billing_period": billingPeriod.rawValue
                ]
            )
            
            isLoading = false
            return subscription
            
        } catch {
            errorMessage = "Erro ao criar assinatura: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Payment History
    func loadPaymentHistory(for patientId: UUID) async -> [PatientPayment] {
        do {
            return try await fetchPaymentsFromDatabase(patientId: patientId)
        } catch {
            errorMessage = "Erro ao carregar histórico: \(error.localizedDescription)"
            showError = true
            return []
        }
    }
    
    // MARK: - Payment Analytics
    func loadPaymentAnalytics(for psychologistId: UUID) async -> PaymentAnalytics? {
        do {
            let payments = try await fetchPaymentsFromDatabase(psychologistId: psychologistId)
            return calculateAnalytics(from: payments)
        } catch {
            errorMessage = "Erro ao carregar analytics: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }
    
    private func calculateAnalytics(from payments: [PatientPayment]) -> PaymentAnalytics {
        let successfulPayments = payments.filter { $0.status == .succeeded }
        let failedPayments = payments.filter { $0.status == .failed }
        
        let totalRevenue = successfulPayments.reduce(Decimal(0)) { $0 + $1.amount }
        let totalTransactions = payments.count
        let successfulTransactions = successfulPayments.count
        let failedTransactions = failedPayments.count
        
        let averageTransactionValue = successfulTransactions > 0 ? 
            totalRevenue / Decimal(successfulTransactions) : Decimal(0)
        
        // Calculate monthly revenue for current month
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let monthlyPayments = successfulPayments.filter { payment in
            let paymentMonth = calendar.component(.month, from: payment.createdAt)
            let paymentYear = calendar.component(.year, from: payment.createdAt)
            return paymentMonth == currentMonth && paymentYear == currentYear
        }
        
        let monthlyRevenue = monthlyPayments.reduce(Decimal(0)) { $0 + $1.amount }
        
        // Calculate payment method analytics
        let paymentMethodCounts = Dictionary(grouping: successfulPayments) { $0.paymentMethodType }
        let topPaymentMethods = paymentMethodCounts.map { (type, payments) in
            PaymentAnalytics.PaymentMethodAnalytics(
                type: type,
                count: payments.count,
                percentage: Double(payments.count) / Double(successfulTransactions) * 100,
                totalAmount: payments.reduce(Decimal(0)) { $0 + $1.amount }
            )
        }.sorted { $0.count > $1.count }
        
        // Calculate revenue by month (last 12 months)
        var revenueByMonth: [PaymentAnalytics.MonthlyRevenue] = []
        for i in 0..<12 {
            let date = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            
            let monthPayments = successfulPayments.filter { payment in
                let paymentMonth = calendar.component(.month, from: payment.createdAt)
                let paymentYear = calendar.component(.year, from: payment.createdAt)
                return paymentMonth == month && paymentYear == year
            }
            
            let monthRevenue = monthPayments.reduce(Decimal(0)) { $0 + $1.amount }
            let monthName = DateFormatter().monthSymbols[month - 1]
            
            revenueByMonth.append(PaymentAnalytics.MonthlyRevenue(
                month: monthName,
                year: year,
                revenue: monthRevenue,
                transactionCount: monthPayments.count
            ))
        }
        
        return PaymentAnalytics(
            totalRevenue: totalRevenue,
            monthlyRevenue: monthlyRevenue,
            totalTransactions: totalTransactions,
            successfulTransactions: successfulTransactions,
            failedTransactions: failedTransactions,
            averageTransactionValue: averageTransactionValue,
            topPaymentMethods: topPaymentMethods,
            revenueByMonth: revenueByMonth.reversed(),
            churnRate: 0.0, // Calculate based on subscription data
            mrr: monthlyRevenue, // Simplified calculation
            arr: monthlyRevenue * 12 // Simplified calculation
        )
    }
    
    // MARK: - Database Operations
    private func savePaymentToDatabase(_ payment: PatientPayment) async throws {
        // Implementation depends on your database choice
        // This could be Supabase, Core Data, etc.
        
        let endpoint = "/api/payments"
        let data = try JSONEncoder().encode(payment)
        
        _ = try await networkManager.request(
            endpoint: endpoint,
            method: .POST,
            body: data
        )
    }
    
    private func updatePaymentInDatabase(_ payment: PatientPayment) async throws {
        let endpoint = "/api/payments/\(payment.id)"
        let data = try JSONEncoder().encode(payment)
        
        _ = try await networkManager.request(
            endpoint: endpoint,
            method: .PUT,
            body: data
        )
    }
    
    private func fetchPaymentsFromDatabase(patientId: UUID) async throws -> [PatientPayment] {
        let endpoint = "/api/payments?patient_id=\(patientId)"
        let data: Data = try await networkManager.request(endpoint: endpoint, method: .GET)
        return try JSONDecoder().decode([PatientPayment].self, from: data)
    }
    
    private func fetchPaymentsFromDatabase(psychologistId: UUID) async throws -> [PatientPayment] {
        let endpoint = "/api/payments?psychologist_id=\(psychologistId)"
        let data: Data = try await networkManager.request(endpoint: endpoint, method: .GET)
        return try JSONDecoder().decode([PatientPayment].self, from: data)
    }
    
    // MARK: - Validation
    func validatePaymentAmount(_ amount: Decimal) -> Bool {
        let config = PaymentConfiguration.default
        let amountInCents = Int(amount * 100)
        return amountInCents >= config.minimumAmount && amountInCents <= config.maximumAmount
    }
    
    func validatePaymentMethod(_ paymentMethod: StripePaymentMethod) -> Bool {
        // Check if payment method is expired
        if let card = paymentMethod.card, card.isExpired {
            return false
        }
        
        // Check if payment method type is supported
        let config = PaymentConfiguration.default
        return config.supportedPaymentMethods.contains(paymentMethod.type)
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    func handleStripeError(_ error: Error) {
        if let stripeError = error as? StripeError {
            switch stripeError.type {
            case .cardError:
                errorMessage = "Erro no cartão: \(stripeError.localizedDescription)"
            case .invalidRequestError:
                errorMessage = "Solicitação inválida: \(stripeError.localizedDescription)"
            case .authenticationError:
                errorMessage = "Erro de autenticação: \(stripeError.localizedDescription)"
            case .apiConnectionError:
                errorMessage = "Erro de conexão: Verifique sua internet"
            case .apiError:
                errorMessage = "Erro interno: Tente novamente"
            case .rateLimitError:
                errorMessage = "Muitas tentativas: Aguarde um momento"
            default:
                errorMessage = "Erro desconhecido: \(stripeError.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}

// MARK: - Extensions
extension PaymentViewModel {
    func formatAmount(_ amount: Decimal, currency: String = "BRL") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
}
