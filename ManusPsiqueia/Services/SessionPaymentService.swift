//
//  SessionPaymentService.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Session Payment Service
@MainActor
class SessionPaymentService: ObservableObject {
    static let shared = SessionPaymentService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionPayments: [SessionPayment] = []
    @Published var currentPayment: SessionPayment?
    
    private let stripeManager = StripeManager.shared
    private let stripeConnectManager = StripeConnectManager.shared
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let feeConfiguration = FeeConfiguration.default
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observar mudanças no estado dos managers
        stripeManager.$isLoading
            .combineLatest(stripeConnectManager.$isLoading)
            .map { $0 || $1 }
            .assign(to: &$isLoading)
    }
    
    // MARK: - Session Payment Processing
    
    /// Processa o pagamento de uma sessão de terapia
    func processSessionPayment(
        sessionId: String,
        psychologist: User,
        patient: User,
        amount: Int,
        description: String
    ) async throws -> SessionPayment {
        
        guard psychologist.userType == .psychologist else {
            throw SessionPaymentError.invalidPsychologist
        }
        
        guard patient.userType == .patient else {
            throw SessionPaymentError.invalidPatient
        }
        
        isLoading = true
        defer { isLoading = false }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Iniciando pagamento de sessão: \(sessionId)"
        )
        
        do {
            // 1. Verificar se o psicólogo tem conta conectada
            let psychologistAccountId = try await getOrCreateConnectedAccount(for: psychologist)
            
            // 2. Verificar se o paciente tem customer ID
            let customerID = try await getOrCreateCustomer(for: patient)
            
            // 3. Calcular taxa da plataforma
            let applicationFee = feeConfiguration.calculateFee(for: amount)
            
            // 4. Criar Payment Intent com Connect
            let clientSecret = try await stripeConnectManager.createDirectPayment(
                amount: amount,
                connectedAccountId: psychologistAccountId,
                applicationFeeAmount: applicationFee,
                customerId: customerID,
                metadata: [
                    "session_id": sessionId,
                    "psychologist_id": psychologist.id.uuidString,
                    "patient_id": patient.id.uuidString,
                    "description": description
                ]
            )
            
            // 5. Criar registro de pagamento da sessão
            let sessionPayment = SessionPayment(
                id: UUID().uuidString,
                sessionId: sessionId,
                psychologistId: psychologist.id.uuidString,
                patientId: patient.id.uuidString,
                amount: amount,
                currency: "brl",
                status: .processing,
                scheduledDate: Date(),
                completedDate: nil,
                paymentMethod: .card,
                description: description
            )
            
            // 6. Salvar no banco de dados local
            sessionPayments.append(sessionPayment)
            currentPayment = sessionPayment
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Pagamento de sessão criado com sucesso: \(sessionPayment.id)"
            )
            
            return sessionPayment
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha no pagamento da sessão: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    /// Confirma o pagamento após a conclusão da sessão
    func confirmSessionPayment(paymentId: String) async throws {
        guard let index = sessionPayments.firstIndex(where: { $0.id == paymentId }) else {
            throw SessionPaymentError.paymentNotFound
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Confirmando pagamento da sessão: \(paymentId)"
        )
        
        do {
            // Atualizar status do pagamento
            sessionPayments[index] = SessionPayment(
                id: sessionPayments[index].id,
                sessionId: sessionPayments[index].sessionId,
                psychologistId: sessionPayments[index].psychologistId,
                patientId: sessionPayments[index].patientId,
                amount: sessionPayments[index].amount,
                currency: sessionPayments[index].currency,
                status: .completed,
                scheduledDate: sessionPayments[index].scheduledDate,
                completedDate: Date(),
                paymentMethod: sessionPayments[index].paymentMethod,
                description: sessionPayments[index].description
            )
            
            // Sincronizar com backend
            try await syncPaymentWithBackend(sessionPayments[index])
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Pagamento da sessão confirmado: \(paymentId)"
            )
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na confirmação do pagamento: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    /// Processa reembolso de uma sessão cancelada
    func refundSessionPayment(paymentId: String, reason: String) async throws {
        guard let index = sessionPayments.firstIndex(where: { $0.id == paymentId }) else {
            throw SessionPaymentError.paymentNotFound
        }
        
        let payment = sessionPayments[index]
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Processando reembolso da sessão: \(paymentId)"
        )
        
        do {
            // Processar reembolso via Stripe
            let refundParameters = [
                "payment_intent": payment.id,
                "reason": "requested_by_customer",
                "metadata[session_id]": payment.sessionId,
                "metadata[reason]": reason
            ]
            
            let response = try await networkManager.post(
                endpoint: "https://api.stripe.com/v1/refunds",
                parameters: refundParameters,
                requiresAuth: true
            )
            
            guard response["status"] as? String == "succeeded" else {
                throw SessionPaymentError.refundFailed
            }
            
            // Atualizar status do pagamento
            sessionPayments[index] = SessionPayment(
                id: payment.id,
                sessionId: payment.sessionId,
                psychologistId: payment.psychologistId,
                patientId: payment.patientId,
                amount: payment.amount,
                currency: payment.currency,
                status: .refunded,
                scheduledDate: payment.scheduledDate,
                completedDate: payment.completedDate,
                paymentMethod: payment.paymentMethod,
                description: payment.description
            )
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Reembolso processado com sucesso: \(paymentId)"
            )
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha no processamento do reembolso: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func getOrCreateConnectedAccount(for psychologist: User) async throws -> String {
        // Tentar buscar account ID existente
        if let existingAccountId = KeychainWrapper.standard.string(forKey: "stripe_connect_\(psychologist.id)") {
            // Verificar se a conta ainda é válida
            do {
                let account = try await stripeConnectManager.getAccountStatus(accountId: existingAccountId)
                if account.status == .active {
                    return existingAccountId
                }
            } catch {
                // Conta inválida, criar nova
            }
        }
        
        // Criar nova conta conectada
        return try await stripeConnectManager.createConnectedAccount(for: psychologist)
    }
    
    private func getOrCreateCustomer(for patient: User) async throws -> String {
        // Tentar buscar customer ID existente
        if let existingCustomerId = KeychainWrapper.standard.string(forKey: "stripe_customer_\(patient.id)") {
            return existingCustomerId
        }
        
        // Criar novo customer
        return try await stripeManager.createCustomer(for: patient)
    }
    
    private func syncPaymentWithBackend(_ payment: SessionPayment) async throws {
        let parameters = [
            "id": payment.id,
            "session_id": payment.sessionId,
            "psychologist_id": payment.psychologistId,
            "patient_id": payment.patientId,
            "amount": String(payment.amount),
            "currency": payment.currency,
            "status": payment.status.rawValue,
            "scheduled_date": ISO8601DateFormatter().string(from: payment.scheduledDate),
            "completed_date": payment.completedDate.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "payment_method": payment.paymentMethod.rawValue,
            "description": payment.description
        ]
        
        _ = try await networkManager.post(
            endpoint: "/api/session-payments",
            parameters: parameters,
            requiresAuth: true
        )
    }
    
    // MARK: - Analytics
    
    /// Obtém analytics de pagamentos para um psicólogo
    func getPaymentAnalytics(for psychologistId: String, period: AnalyticsPeriod) async throws -> ConnectAnalytics {
        let psychologistPayments = sessionPayments.filter { $0.psychologistId == psychologistId }
        
        let totalRevenue = psychologistPayments
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.amount }
        
        let totalFees = psychologistPayments
            .filter { $0.status == .completed }
            .reduce(0) { $0 + feeConfiguration.calculateFee(for: $1.amount) }
        
        let totalPayouts = totalRevenue - totalFees
        let transactionCount = psychologistPayments.filter { $0.status == .completed }.count
        let averageTransaction = transactionCount > 0 ? totalRevenue / transactionCount : 0
        
        return ConnectAnalytics(
            totalRevenue: totalRevenue,
            totalFees: totalFees,
            totalPayouts: totalPayouts,
            transactionCount: transactionCount,
            averageTransactionAmount: averageTransaction,
            period: period,
            lastUpdated: Date()
        )
    }
    
    /// Obtém histórico de pagamentos para um usuário
    func getPaymentHistory(for userId: String, userType: UserType) -> [SessionPayment] {
        switch userType {
        case .psychologist:
            return sessionPayments.filter { $0.psychologistId == userId }
        case .patient:
            return sessionPayments.filter { $0.patientId == userId }
        case .admin:
            return sessionPayments
        }
    }
    
    // MARK: - Cleanup
    
    func clearSensitiveData() {
        currentPayment = nil
        errorMessage = nil
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Dados sensíveis do serviço de pagamento limpos"
        )
    }
}

// MARK: - Errors

enum SessionPaymentError: LocalizedError {
    case invalidPsychologist
    case invalidPatient
    case paymentNotFound
    case refundFailed
    case insufficientFunds
    case accountNotSetup
    case sessionNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPsychologist:
            return "Psicólogo inválido para processamento de pagamento"
        case .invalidPatient:
            return "Paciente inválido para processamento de pagamento"
        case .paymentNotFound:
            return "Pagamento não encontrado"
        case .refundFailed:
            return "Falha no processamento do reembolso"
        case .insufficientFunds:
            return "Fundos insuficientes"
        case .accountNotSetup:
            return "Conta de pagamento não configurada"
        case .sessionNotFound:
            return "Sessão não encontrada"
        }
    }
}
