//
//  StripeConnectManager.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Stripe
import StripeConnect
import SwiftKeychainWrapper

// MARK: - Stripe Connect Manager
@MainActor
class StripeConnectManager: ObservableObject {
    static let shared = StripeConnectManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var connectedAccounts: [ConnectedAccount] = []
    @Published var currentAccountLink: String?
    @Published var onboardingStatus: OnboardingStatus = .notStarted
    
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let baseURL = "https://api.stripe.com/v1"
    private let keychainService = "ManusPsiqueia.StripeConnect"
    
    // MARK: - Connect Account Management
    
    /// Cria uma conta conectada para um psicólogo
    func createConnectedAccount(for psychologist: User) async throws -> String {
        guard psychologist.userType == .psychologist else {
            throw StripeConnectError.invalidUserType
        }
        
        isLoading = true
        defer { isLoading = false }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando conta conectada para psicólogo: \(psychologist.id)"
        )
        
        let parameters = [
            "type": "express",
            "country": "BR",
            "email": psychologist.email,
            "capabilities[card_payments][requested]": "true",
            "capabilities[transfers][requested]": "true",
            "business_type": "individual",
            "metadata[user_id]": psychologist.id.uuidString,
            "metadata[user_type]": "psychologist",
            "metadata[platform]": "ManusPsiqueia_iOS"
        ]
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/accounts",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let accountId = response["id"] as? String else {
                throw StripeConnectError.invalidResponse
            }
            
            // Armazenar account ID de forma segura
            KeychainWrapper.standard.set(accountId, forKey: "stripe_connect_\(psychologist.id)")
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Conta conectada criada: \(accountId)"
            )
            
            return accountId
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação da conta conectada: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    /// Cria um link de onboarding para a conta conectada
    func createAccountLink(accountId: String, returnURL: String, refreshURL: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "account": accountId,
            "return_url": returnURL,
            "refresh_url": refreshURL,
            "type": "account_onboarding"
        ]
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando link de onboarding para conta: \(accountId)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/account_links",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let url = response["url"] as? String else {
                throw StripeConnectError.invalidResponse
            }
            
            currentAccountLink = url
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Link de onboarding criado com sucesso"
            )
            
            return url
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação do link de onboarding: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    /// Verifica o status de uma conta conectada
    func getAccountStatus(accountId: String) async throws -> ConnectedAccount {
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Verificando status da conta: \(accountId)"
        )
        
        do {
            let response = try await networkManager.get(
                endpoint: "\(baseURL)/accounts/\(accountId)",
                requiresAuth: true
            )
            
            let account = try parseConnectedAccount(from: response)
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Status da conta obtido: \(account.status)"
            )
            
            return account
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha ao obter status da conta: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Payment Processing
    
    /// Cria um pagamento direto para uma conta conectada
    func createDirectPayment(
        amount: Int,
        currency: String = "brl",
        connectedAccountId: String,
        applicationFeeAmount: Int,
        customerId: String,
        metadata: [String: String] = [:]
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "amount": String(amount),
            "currency": currency,
            "customer": customerId,
            "application_fee_amount": String(applicationFeeAmount),
            "transfer_data[destination]": connectedAccountId,
            "automatic_payment_methods[enabled]": "true"
        ]
        
        // Metadata de segurança
        var secureMetadata = metadata
        secureMetadata["platform"] = "ManusPsiqueia_iOS"
        secureMetadata["payment_type"] = "direct_charge"
        secureMetadata["connected_account"] = connectedAccountId
        
        for (key, value) in secureMetadata {
            parameters["metadata[\(key)]"] = value
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando pagamento direto - Valor: \(amount) \(currency), Taxa: \(applicationFeeAmount)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/payment_intents",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let paymentIntentId = response["id"] as? String,
                  let clientSecret = response["client_secret"] as? String else {
                throw StripeConnectError.invalidResponse
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Pagamento direto criado: \(paymentIntentId)"
            )
            
            return clientSecret
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação do pagamento direto: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    /// Cria uma transferência para uma conta conectada
    func createTransfer(
        amount: Int,
        currency: String = "brl",
        destinationAccountId: String,
        metadata: [String: String] = [:]
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "amount": String(amount),
            "currency": currency,
            "destination": destinationAccountId
        ]
        
        // Metadata de segurança
        var secureMetadata = metadata
        secureMetadata["platform"] = "ManusPsiqueia_iOS"
        secureMetadata["transfer_type"] = "manual"
        
        for (key, value) in secureMetadata {
            parameters["metadata[\(key)]"] = value
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando transferência - Valor: \(amount) \(currency) para conta: \(destinationAccountId)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/transfers",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let transferId = response["id"] as? String else {
                throw StripeConnectError.invalidResponse
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Transferência criada: \(transferId)"
            )
            
            return transferId
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação da transferência: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Dashboard Links
    
    /// Cria um link para o dashboard da conta conectada
    func createDashboardLink(accountId: String) async throws -> String {
        let parameters = [
            "account": accountId
        ]
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando link do dashboard para conta: \(accountId)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/accounts/\(accountId)/login_links",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let url = response["url"] as? String else {
                throw StripeConnectError.invalidResponse
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Link do dashboard criado com sucesso"
            )
            
            return url
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação do link do dashboard: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseConnectedAccount(from response: [String: Any]) throws -> ConnectedAccount {
        guard let id = response["id"] as? String,
              let email = response["email"] as? String else {
            throw StripeConnectError.invalidResponse
        }
        
        let chargesEnabled = response["charges_enabled"] as? Bool ?? false
        let payoutsEnabled = response["payouts_enabled"] as? Bool ?? false
        let detailsSubmitted = response["details_submitted"] as? Bool ?? false
        
        let status: ConnectedAccountStatus
        if chargesEnabled && payoutsEnabled {
            status = .active
        } else if detailsSubmitted {
            status = .pending
        } else {
            status = .incomplete
        }
        
        return ConnectedAccount(
            id: id,
            email: email,
            status: status,
            chargesEnabled: chargesEnabled,
            payoutsEnabled: payoutsEnabled,
            detailsSubmitted: detailsSubmitted
        )
    }
    
    /// Limpa dados sensíveis da memória
    func clearSensitiveData() {
        currentAccountLink = nil
        errorMessage = nil
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Dados sensíveis do Stripe Connect limpos da memória"
        )
    }
}

// MARK: - Models

struct ConnectedAccount: Identifiable, Codable {
    let id: String
    let email: String
    let status: ConnectedAccountStatus
    let chargesEnabled: Bool
    let payoutsEnabled: Bool
    let detailsSubmitted: Bool
}

enum ConnectedAccountStatus: String, Codable, CaseIterable {
    case incomplete = "incomplete"
    case pending = "pending"
    case active = "active"
    case restricted = "restricted"
    
    var displayName: String {
        switch self {
        case .incomplete:
            return "Incompleto"
        case .pending:
            return "Pendente"
        case .active:
            return "Ativo"
        case .restricted:
            return "Restrito"
        }
    }
    
    var color: Color {
        switch self {
        case .incomplete:
            return .red
        case .pending:
            return .orange
        case .active:
            return .green
        case .restricted:
            return .red
        }
    }
}

enum OnboardingStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Não Iniciado"
        case .inProgress:
            return "Em Andamento"
        case .completed:
            return "Concluído"
        case .failed:
            return "Falhou"
        }
    }
}

// MARK: - Errors

enum StripeConnectError: LocalizedError {
    case invalidUserType
    case invalidResponse
    case accountNotFound
    case onboardingIncomplete
    case transferFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidUserType:
            return "Tipo de usuário inválido para Stripe Connect"
        case .invalidResponse:
            return "Resposta inválida do Stripe Connect"
        case .accountNotFound:
            return "Conta conectada não encontrada"
        case .onboardingIncomplete:
            return "Onboarding da conta não foi concluído"
        case .transferFailed:
            return "Falha na transferência"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        }
    }
}
