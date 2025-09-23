//
//  StripeManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Stripe
import StripePaymentSheet
import StripePayments
import StripePaymentsUI
import SwiftKeychainWrapper

// MARK: - Stripe Manager
@MainActor
class StripeManager: ObservableObject {
    static let shared = StripeManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var currentPaymentIntent: String?
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Security Configuration
    private let publishableKey: String
    private let baseURL = "https://api.stripe.com/v1"
    private let keychainService = "ManusPsiqueia.Stripe"
    
    // MARK: - PCI DSS Compliance
    private let auditLogger = AuditLogger.shared
    
    init() {
        // Configuração segura das chaves usando o StripeSecurityManager
        self.publishableKey = getSecureStripeKey()
        setupStripe()
        configureSecurityMeasures()
    }
    
    private func getSecureStripeKey() -> String {
        do {
            // Usar o StripeSecurityManager para obter a chave de forma segura
            return try StripeSecurityManager.shared.getStripeKey(type: .publishable)
        } catch {
            auditLogger.log(
                event: .securityEvent,
                severity: .critical,
                details: "Falha ao obter chave publicável do Stripe: \(error.localizedDescription)"
            )
            
            // Fallback para environment apenas em desenvolvimento
            #if DEBUG
            return ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY_DEV"] ?? "pk_test_..."
            #else
            fatalError("Chave publicável do Stripe não configurada para produção")
            #endif
        }
    }
    
    private func setupStripe() {
        StripeAPI.defaultPublishableKey = publishableKey
        
        // Configurações de segurança
        let configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "ManusPsiqueia"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "manuspsiqueia://stripe-redirect"
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Stripe SDK configurado com segurança"
        )
    }
    
    private func configureSecurityMeasures() {
        // Configuração de timeout para requests
        URLSession.shared.configuration.timeoutIntervalForRequest = 30
        URLSession.shared.configuration.timeoutIntervalForResource = 60
        
        // Log de inicialização segura
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Medidas de segurança PCI DSS ativadas"
        )
    }
    
    // MARK: - Customer Management
    func createCustomer(for user: User) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Tentativa de criação de cliente Stripe para usuário: \(user.id)"
        )
        
        let parameters = [
            "email": user.email,
            "name": user.fullName,
            "metadata[user_id]": user.id.uuidString,
            "metadata[user_type]": user.userType.rawValue,
            "metadata[platform]": "ManusPsiqueia_iOS"
        ]
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/customers",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let customerId = response["id"] as? String else {
                throw StripeError.invalidResponse
            }
            
            // Armazenar customer ID de forma segura
            KeychainWrapper.standard.set(customerId, forKey: "stripe_customer_\(user.id)")
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Cliente Stripe criado com sucesso"
            )
            
            return customerId
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação do cliente: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Payment Intent Management
    func createPaymentIntent(
        amount: Int,
        currency: String = "brl",
        customerId: String,
        metadata: [String: String] = [:]
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "amount": String(amount),
            "currency": currency,
            "customer": customerId,
            "automatic_payment_methods[enabled]": "true",
            "setup_future_usage": "off_session"
        ]
        
        // Adicionar metadata de segurança
        var secureMetadata = metadata
        secureMetadata["platform"] = "ManusPsiqueia_iOS"
        secureMetadata["created_at"] = ISO8601DateFormatter().string(from: Date())
        
        for (key, value) in secureMetadata {
            parameters["metadata[\(key)]"] = value
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando Payment Intent - Valor: \(amount) \(currency)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/payment_intents",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let paymentIntentId = response["id"] as? String,
                  let clientSecret = response["client_secret"] as? String else {
                throw StripeError.invalidResponse
            }
            
            currentPaymentIntent = paymentIntentId
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Payment Intent criado: \(paymentIntentId)"
            )
            
            return clientSecret
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação do Payment Intent: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Payment Sheet
    func presentPaymentSheet(
        clientSecret: String,
        configuration: PaymentSheet.Configuration? = nil
    ) async throws {
        
        let config = configuration ?? createDefaultConfiguration()
        
        do {
            paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
            
            auditLogger.log(
                event: .networkRequest,
                severity: .info,
                details: "Payment Sheet apresentado ao usuário"
            )
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Erro ao apresentar Payment Sheet: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    private func createDefaultConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "ManusPsiqueia - Plataforma de Saúde Mental"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "manuspsiqueia://stripe-redirect"
        
        // Configurações de aparência
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        appearance.cornerRadius = 12
        configuration.appearance = appearance
        
        return configuration
    }
    
    // MARK: - Subscription Management
    func createSubscription(
        customerId: String,
        priceId: String,
        metadata: [String: String] = [:]
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "customer": customerId,
            "items[0][price]": priceId,
            "payment_behavior": "default_incomplete",
            "payment_settings[save_default_payment_method]": "on_subscription",
            "expand[]": "latest_invoice.payment_intent"
        ]
        
        // Metadata de segurança
        var secureMetadata = metadata
        secureMetadata["platform"] = "ManusPsiqueia_iOS"
        secureMetadata["subscription_type"] = "recurring"
        
        for (key, value) in secureMetadata {
            parameters["metadata[\(key)]"] = value
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Criando assinatura para cliente: \(customerId)"
        )
        
        do {
            let response = try await networkManager.post(
                endpoint: "\(baseURL)/subscriptions",
                parameters: parameters,
                requiresAuth: true
            )
            
            guard let subscriptionId = response["id"] as? String else {
                throw StripeError.invalidResponse
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Assinatura criada: \(subscriptionId)"
            )
            
            return subscriptionId
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha na criação da assinatura: \(error.localizedDescription)"
            )
            throw error
        }
    }
    
    // MARK: - Error Handling
    func handlePaymentSheetResult(_ result: PaymentSheetResult) {
        paymentResult = result
        
        switch result {
        case .completed:
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Pagamento completado com sucesso"
            )
            errorMessage = nil
            
        case .canceled:
            auditLogger.log(
                event: .networkRequest,
                severity: .info,
                details: "Pagamento cancelado pelo usuário"
            )
            errorMessage = "Pagamento cancelado"
            
        case .failed(let error):
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Erro no pagamento: \(error.localizedDescription)"
            )
            errorMessage = "Erro no pagamento: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Webhook Integration
    
    /// Processes webhook events received from Stripe
    func processWebhook(_ event: StripeWebhookEvent, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            let result = await WebhookManager.shared.processWebhookWithRetry(event)
            
            switch result {
            case .success(let message):
                completion(.success(message))
            case .failure(let error):
                completion(.failure(error))
            case .ignored(let reason):
                completion(.success("Event ignored: \(reason)"))
            }
        }
    }
    
    /// Validates webhook signature for security
    func validateWebhook(payload: Data, signature: String, secret: String) -> Bool {
        return WebhookManager.shared.validateWebhook(payload: payload, signature: signature, secret: secret)
    }
    
    // MARK: - Security Utilities
    func clearSensitiveData() {
        currentPaymentIntent = nil
        paymentSheet = nil
        paymentResult = nil
        errorMessage = nil
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Dados sensíveis limpos da memória"
        )
    }
}

// MARK: - Stripe Errors
enum StripeError: LocalizedError {
    case invalidResponse
    case invalidWebhookSignature
    case invalidWebhookPayload
    case networkError(Error)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do Stripe"
        case .invalidWebhookSignature:
            return "Assinatura do webhook inválida"
        case .invalidWebhookPayload:
            return "Payload do webhook inválido"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        case .configurationError(let message):
            return "Erro de configuração: \(message)"
        }
    }
}

// MARK: - Payment Method Model
struct PaymentMethod: Identifiable, Codable {
    let id: String
    let type: String
    let card: Card?
    
    struct Card: Codable {
        let brand: String
        let last4: String
        let expMonth: Int
        let expYear: Int
    }
}
