//
//  StripeBackendService.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Stripe Backend Service
@MainActor
class StripeBackendService: ObservableObject {
    static let shared = StripeBackendService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let securityManager = StripeSecurityManager.shared
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let baseURL = "https://api.stripe.com/v1"
    private let timeout: TimeInterval = 30
    
    init() {
        setupNetworkConfiguration()
    }
    
    private func setupNetworkConfiguration() {
        // Configurar timeout e headers de segurança
        URLSession.shared.configuration.timeoutIntervalForRequest = timeout
        URLSession.shared.configuration.timeoutIntervalForResource = timeout * 2
    }
    
    // MARK: - Authenticated Requests
    
    /// Faz uma requisição autenticada para a API do Stripe usando a chave secreta
    private func makeAuthenticatedRequest(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any] = [:],
        environment: BuildEnvironment? = nil
    ) async throws -> [String: Any] {
        
        isLoading = true
        defer { isLoading = false }
        
        // Obter chave secreta do ambiente atual
        let secretKey = try securityManager.getStripeKey(type: .secret, environment: environment)
        
        // Preparar URL
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw StripeBackendError.invalidURL
        }
        
        // Criar requisição
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // Headers de autenticação e segurança
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("ManusPsiqueia/1.0 iOS", forHTTPHeaderField: "User-Agent")
        request.setValue("2023-10-16", forHTTPHeaderField: "Stripe-Version")
        
        // Adicionar parâmetros para POST/PUT
        if method != .GET && !parameters.isEmpty {
            let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Requisição autenticada para Stripe: \(method.rawValue) \(endpoint)"
        )
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StripeBackendError.invalidResponse
            }
            
            // Verificar status code
            guard 200...299 ~= httpResponse.statusCode else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["error"] as? [String: Any]
                let message = errorMessage?["message"] as? String ?? "Erro desconhecido"
                
                auditLogger.log(
                    event: .networkRequestFailed,
                    severity: .critical,
                    details: "Erro na API Stripe: \(httpResponse.statusCode) - \(message)"
                )
                
                throw StripeBackendError.apiError(httpResponse.statusCode, message)
            }
            
            // Parse da resposta
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw StripeBackendError.invalidResponse
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Requisição Stripe bem-sucedida: \(endpoint)"
            )
            
            return jsonResponse
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na requisição Stripe: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Customer Operations
    
    /// Cria um cliente no Stripe usando a API backend
    func createCustomer(
        email: String,
        name: String,
        metadata: [String: String] = [:]
    ) async throws -> StripeCustomer {
        
        var parameters: [String: Any] = [
            "email": email,
            "name": name
        ]
        
        // Adicionar metadata
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "customers",
            method: .POST,
            parameters: parameters
        )
        
        return try parseCustomer(from: response)
    }
    
    /// Atualiza um cliente no Stripe
    func updateCustomer(
        customerId: String,
        email: String? = nil,
        name: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> StripeCustomer {
        
        var parameters: [String: Any] = [:]
        
        if let email = email {
            parameters["email"] = email
        }
        
        if let name = name {
            parameters["name"] = name
        }
        
        // Adicionar metadata
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "customers/\(customerId)",
            method: .POST,
            parameters: parameters
        )
        
        return try parseCustomer(from: response)
    }
    
    /// Busca um cliente no Stripe
    func getCustomer(customerId: String) async throws -> StripeCustomer {
        let response = try await makeAuthenticatedRequest(
            endpoint: "customers/\(customerId)"
        )
        
        return try parseCustomer(from: response)
    }
    
    // MARK: - Connect Account Operations
    
    /// Cria uma conta conectada no Stripe
    func createConnectAccount(
        type: String = "express",
        country: String = "BR",
        email: String,
        metadata: [String: String] = [:]
    ) async throws -> StripeConnectAccount {
        
        var parameters: [String: Any] = [
            "type": type,
            "country": country,
            "email": email,
            "capabilities[card_payments][requested]": "true",
            "capabilities[transfers][requested]": "true"
        ]
        
        // Adicionar metadata
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "accounts",
            method: .POST,
            parameters: parameters
        )
        
        return try parseConnectAccount(from: response)
    }
    
    /// Busca informações de uma conta conectada
    func getConnectAccount(accountId: String) async throws -> StripeConnectAccount {
        let response = try await makeAuthenticatedRequest(
            endpoint: "accounts/\(accountId)"
        )
        
        return try parseConnectAccount(from: response)
    }
    
    /// Cria um link de onboarding para conta conectada
    func createAccountLink(
        accountId: String,
        returnURL: String,
        refreshURL: String,
        type: String = "account_onboarding"
    ) async throws -> String {
        
        let parameters: [String: Any] = [
            "account": accountId,
            "return_url": returnURL,
            "refresh_url": refreshURL,
            "type": type
        ]
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "account_links",
            method: .POST,
            parameters: parameters
        )
        
        guard let url = response["url"] as? String else {
            throw StripeBackendError.missingRequiredField("url")
        }
        
        return url
    }
    
    // MARK: - Payment Intent Operations
    
    /// Cria um Payment Intent com Connect
    func createPaymentIntent(
        amount: Int,
        currency: String = "brl",
        customerId: String? = nil,
        connectedAccountId: String? = nil,
        applicationFeeAmount: Int? = nil,
        metadata: [String: String] = [:]
    ) async throws -> StripePaymentIntent {
        
        var parameters: [String: Any] = [
            "amount": String(amount),
            "currency": currency,
            "automatic_payment_methods[enabled]": "true"
        ]
        
        if let customerId = customerId {
            parameters["customer"] = customerId
        }
        
        if let connectedAccountId = connectedAccountId {
            parameters["transfer_data[destination]"] = connectedAccountId
        }
        
        if let applicationFeeAmount = applicationFeeAmount {
            parameters["application_fee_amount"] = String(applicationFeeAmount)
        }
        
        // Adicionar metadata
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "payment_intents",
            method: .POST,
            parameters: parameters
        )
        
        return try parsePaymentIntent(from: response)
    }
    
    /// Confirma um Payment Intent
    func confirmPaymentIntent(
        paymentIntentId: String,
        paymentMethodId: String? = nil
    ) async throws -> StripePaymentIntent {
        
        var parameters: [String: Any] = [:]
        
        if let paymentMethodId = paymentMethodId {
            parameters["payment_method"] = paymentMethodId
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "payment_intents/\(paymentIntentId)/confirm",
            method: .POST,
            parameters: parameters
        )
        
        return try parsePaymentIntent(from: response)
    }
    
    // MARK: - Transfer Operations
    
    /// Cria uma transferência para conta conectada
    func createTransfer(
        amount: Int,
        currency: String = "brl",
        destinationAccountId: String,
        metadata: [String: String] = [:]
    ) async throws -> StripeTransfer {
        
        var parameters: [String: Any] = [
            "amount": String(amount),
            "currency": currency,
            "destination": destinationAccountId
        ]
        
        // Adicionar metadata
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let response = try await makeAuthenticatedRequest(
            endpoint: "transfers",
            method: .POST,
            parameters: parameters
        )
        
        return try parseTransfer(from: response)
    }
    
    // MARK: - Webhook Operations
    
    /// Valida um webhook do Stripe
    func validateWebhook(
        payload: Data,
        signature: String,
        environment: BuildEnvironment? = nil
    ) throws -> Bool {
        
        let webhookSecret = try securityManager.getStripeKey(type: .webhook, environment: environment)
        
        // Implementar validação de assinatura do webhook
        return StripeConnectWebhookManager.shared.validateWebhookSignature(
            payload: payload,
            signature: signature
        )
    }
    
    // MARK: - Parsing Methods
    
    private func parseCustomer(from response: [String: Any]) throws -> StripeCustomer {
        guard let id = response["id"] as? String,
              let email = response["email"] as? String else {
            throw StripeBackendError.missingRequiredField("id or email")
        }
        
        let name = response["name"] as? String
        let metadata = response["metadata"] as? [String: String] ?? [:]
        
        return StripeCustomer(
            id: id,
            email: email,
            name: name,
            metadata: metadata
        )
    }
    
    private func parseConnectAccount(from response: [String: Any]) throws -> StripeConnectAccount {
        guard let id = response["id"] as? String else {
            throw StripeBackendError.missingRequiredField("id")
        }
        
        let email = response["email"] as? String
        let chargesEnabled = response["charges_enabled"] as? Bool ?? false
        let payoutsEnabled = response["payouts_enabled"] as? Bool ?? false
        let detailsSubmitted = response["details_submitted"] as? Bool ?? false
        
        return StripeConnectAccount(
            id: id,
            email: email,
            chargesEnabled: chargesEnabled,
            payoutsEnabled: payoutsEnabled,
            detailsSubmitted: detailsSubmitted
        )
    }
    
    private func parsePaymentIntent(from response: [String: Any]) throws -> StripePaymentIntent {
        guard let id = response["id"] as? String,
              let clientSecret = response["client_secret"] as? String,
              let statusString = response["status"] as? String else {
            throw StripeBackendError.missingRequiredField("id, client_secret or status")
        }
        
        let amount = response["amount"] as? Int ?? 0
        let currency = response["currency"] as? String ?? "brl"
        
        return StripePaymentIntent(
            id: id,
            clientSecret: clientSecret,
            amount: amount,
            currency: currency,
            status: statusString
        )
    }
    
    private func parseTransfer(from response: [String: Any]) throws -> StripeTransfer {
        guard let id = response["id"] as? String else {
            throw StripeBackendError.missingRequiredField("id")
        }
        
        let amount = response["amount"] as? Int ?? 0
        let currency = response["currency"] as? String ?? "brl"
        let destination = response["destination"] as? String ?? ""
        
        return StripeTransfer(
            id: id,
            amount: amount,
            currency: currency,
            destination: destination
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

struct StripeCustomer {
    let id: String
    let email: String
    let name: String?
    let metadata: [String: String]
}

struct StripeConnectAccount {
    let id: String
    let email: String?
    let chargesEnabled: Bool
    let payoutsEnabled: Bool
    let detailsSubmitted: Bool
}

struct StripePaymentIntent {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
}

struct StripeTransfer {
    let id: String
    let amount: Int
    let currency: String
    let destination: String
}

// MARK: - Errors

enum StripeBackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingRequiredField(String)
    case apiError(Int, String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Resposta inválida da API"
        case .missingRequiredField(let field):
            return "Campo obrigatório ausente: \(field)"
        case .apiError(let code, let message):
            return "Erro da API (\(code)): \(message)"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        }
    }
}
