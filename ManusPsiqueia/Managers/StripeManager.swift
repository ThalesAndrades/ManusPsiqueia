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

// MARK: - Stripe Manager
@MainActor
class StripeManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var currentPaymentIntent: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let publishableKey: String
    private let baseURL = "https://api.stripe.com/v1"
    
    init() {
        // Em produção, isso viria de um arquivo de configuração seguro
        self.publishableKey = ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"] ?? "pk_test_..."
        
        setupStripe()
    }
    
    private func setupStripe() {
        // Configuração inicial do Stripe SDK
        // Em uma implementação real, você usaria o Stripe SDK oficial
        print("Stripe configurado com chave: \(publishableKey.prefix(20))...")
    }
    
    // MARK: - Customer Management
    func createCustomer(for user: User) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "email": user.email,
            "name": user.fullName,
            "metadata[user_id]": user.id.uuidString,
            "metadata[user_type]": user.userType.rawValue
        ]
        
        do {
            let response: StripeCustomerResponse = try await networkManager.post(
                endpoint: "/stripe/customers",
                parameters: parameters
            )
            return response.id
        } catch {
            errorMessage = "Erro ao criar cliente: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getCustomer(customerId: String) async throws -> StripeCustomer {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customer: StripeCustomer = try await networkManager.get(
                endpoint: "/stripe/customers/\(customerId)"
            )
            return customer
        } catch {
            errorMessage = "Erro ao buscar cliente: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Payment Methods
    func attachPaymentMethod(paymentMethodId: String, customerId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "customer": customerId
        ]
        
        do {
            let _: StripePaymentMethodResponse = try await networkManager.post(
                endpoint: "/stripe/payment_methods/\(paymentMethodId)/attach",
                parameters: parameters
            )
        } catch {
            errorMessage = "Erro ao anexar método de pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getPaymentMethods(customerId: String) async throws -> [PaymentMethod] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: StripePaymentMethodsResponse = try await networkManager.get(
                endpoint: "/stripe/customers/\(customerId)/payment_methods"
            )
            
            let paymentMethods = response.data.map { stripeMethod in
                PaymentMethod(
                    id: stripeMethod.id,
                    type: .card, // Simplificado para este exemplo
                    last4: stripeMethod.card?.last4,
                    brand: stripeMethod.card?.brand,
                    expiryMonth: stripeMethod.card?.expMonth,
                    expiryYear: stripeMethod.card?.expYear,
                    stripePaymentMethodId: stripeMethod.id
                )
            }
            
            DispatchQueue.main.async {
                self.paymentMethods = paymentMethods
            }
            
            return paymentMethods
        } catch {
            errorMessage = "Erro ao buscar métodos de pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deletePaymentMethod(paymentMethodId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _: StripePaymentMethodResponse = try await networkManager.delete(
                endpoint: "/stripe/payment_methods/\(paymentMethodId)"
            )
            
            // Remover da lista local
            DispatchQueue.main.async {
                self.paymentMethods.removeAll { $0.stripePaymentMethodId == paymentMethodId }
            }
        } catch {
            errorMessage = "Erro ao remover método de pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Subscriptions
    func createSubscription(
        customerId: String,
        priceId: String,
        paymentMethodId: String
    ) async throws -> StripeSubscription {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "customer": customerId,
            "items[0][price]": priceId,
            "default_payment_method": paymentMethodId,
            "expand[]": "latest_invoice.payment_intent"
        ]
        
        do {
            let subscription: StripeSubscription = try await networkManager.post(
                endpoint: "/stripe/subscriptions",
                parameters: parameters
            )
            return subscription
        } catch {
            errorMessage = "Erro ao criar assinatura: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getSubscription(subscriptionId: String) async throws -> StripeSubscription {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let subscription: StripeSubscription = try await networkManager.get(
                endpoint: "/stripe/subscriptions/\(subscriptionId)"
            )
            return subscription
        } catch {
            errorMessage = "Erro ao buscar assinatura: \(error.localizedDescription)"
            throw error
        }
    }
    
    func cancelSubscription(subscriptionId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _: StripeSubscription = try await networkManager.delete(
                endpoint: "/stripe/subscriptions/\(subscriptionId)"
            )
        } catch {
            errorMessage = "Erro ao cancelar assinatura: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateSubscription(
        subscriptionId: String,
        priceId: String
    ) async throws -> StripeSubscription {
        isLoading = true
        defer { isLoading = false }
        
        // Primeiro, buscar a assinatura atual para obter o item ID
        let currentSubscription = try await getSubscription(subscriptionId: subscriptionId)
        guard let itemId = currentSubscription.items.data.first?.id else {
            throw StripeError.invalidSubscription
        }
        
        let parameters = [
            "items[0][id]": itemId,
            "items[0][price]": priceId
        ]
        
        do {
            let subscription: StripeSubscription = try await networkManager.post(
                endpoint: "/stripe/subscriptions/\(subscriptionId)",
                parameters: parameters
            )
            return subscription
        } catch {
            errorMessage = "Erro ao atualizar assinatura: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Payment Intents
    func createPaymentIntent(
        amount: Int, // Em centavos
        currency: String = "brl",
        customerId: String,
        paymentMethodId: String? = nil
    ) async throws -> StripePaymentIntent {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "amount": String(amount),
            "currency": currency,
            "customer": customerId,
            "automatic_payment_methods[enabled]": "true"
        ]
        
        if let paymentMethodId = paymentMethodId {
            parameters["payment_method"] = paymentMethodId
            parameters["confirm"] = "true"
        }
        
        do {
            let paymentIntent: StripePaymentIntent = try await networkManager.post(
                endpoint: "/stripe/payment_intents",
                parameters: parameters
            )
            
            DispatchQueue.main.async {
                self.currentPaymentIntent = paymentIntent.id
            }
            
            return paymentIntent
        } catch {
            errorMessage = "Erro ao criar intenção de pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    func confirmPaymentIntent(
        paymentIntentId: String,
        paymentMethodId: String
    ) async throws -> StripePaymentIntent {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "payment_method": paymentMethodId
        ]
        
        do {
            let paymentIntent: StripePaymentIntent = try await networkManager.post(
                endpoint: "/stripe/payment_intents/\(paymentIntentId)/confirm",
                parameters: parameters
            )
            return paymentIntent
        } catch {
            errorMessage = "Erro ao confirmar pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Connect (Para psicólogos receberem pagamentos)
    func createConnectAccount(for psychologist: User) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "type": "express",
            "country": "BR",
            "email": psychologist.email,
            "metadata[user_id]": psychologist.id.uuidString,
            "metadata[user_type]": "psychologist"
        ]
        
        do {
            let response: StripeAccountResponse = try await networkManager.post(
                endpoint: "/stripe/accounts",
                parameters: parameters
            )
            return response.id
        } catch {
            errorMessage = "Erro ao criar conta Connect: \(error.localizedDescription)"
            throw error
        }
    }
    
    func createAccountLink(accountId: String, returnURL: String, refreshURL: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "account": accountId,
            "return_url": returnURL,
            "refresh_url": refreshURL,
            "type": "account_onboarding"
        ]
        
        do {
            let response: StripeAccountLinkResponse = try await networkManager.post(
                endpoint: "/stripe/account_links",
                parameters: parameters
            )
            return response.url
        } catch {
            errorMessage = "Erro ao criar link de onboarding: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getAccount(accountId: String) async throws -> StripeAccount {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let account: StripeAccount = try await networkManager.get(
                endpoint: "/stripe/accounts/\(accountId)"
            )
            return account
        } catch {
            errorMessage = "Erro ao buscar conta: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Transfers (Para pagar psicólogos)
    func createTransfer(
        amount: Int, // Em centavos
        destinationAccountId: String,
        transferGroup: String? = nil
    ) async throws -> StripeTransfer {
        isLoading = true
        defer { isLoading = false }
        
        var parameters = [
            "amount": String(amount),
            "currency": "brl",
            "destination": destinationAccountId
        ]
        
        if let transferGroup = transferGroup {
            parameters["transfer_group"] = transferGroup
        }
        
        do {
            let transfer: StripeTransfer = try await networkManager.post(
                endpoint: "/stripe/transfers",
                parameters: parameters
            )
            return transfer
        } catch {
            errorMessage = "Erro ao criar transferência: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Webhooks
    func handleWebhook(payload: Data, signature: String) async throws {
        // Em uma implementação real, você verificaria a assinatura do webhook
        // e processaria os eventos do Stripe
        
        do {
            if let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any],
               let type = json["type"] as? String {
                
                switch type {
                case "payment_intent.succeeded":
                    await handlePaymentSucceeded(json)
                case "payment_intent.payment_failed":
                    await handlePaymentFailed(json)
                case "customer.subscription.created":
                    await handleSubscriptionCreated(json)
                case "customer.subscription.updated":
                    await handleSubscriptionUpdated(json)
                case "customer.subscription.deleted":
                    await handleSubscriptionDeleted(json)
                case "invoice.payment_succeeded":
                    await handleInvoicePaymentSucceeded(json)
                case "invoice.payment_failed":
                    await handleInvoicePaymentFailed(json)
                default:
                    print("Evento não tratado: \(type)")
                }
            }
        } catch {
            print("Erro ao processar webhook: \(error)")
            throw error
        }
    }
    
    private func handlePaymentSucceeded(_ data: [String: Any]) async {
        // Implementar lógica para pagamento bem-sucedido
        print("Pagamento bem-sucedido: \(data)")
    }
    
    private func handlePaymentFailed(_ data: [String: Any]) async {
        // Implementar lógica para pagamento falhado
        print("Pagamento falhado: \(data)")
    }
    
    private func handleSubscriptionCreated(_ data: [String: Any]) async {
        // Implementar lógica para assinatura criada
        print("Assinatura criada: \(data)")
    }
    
    private func handleSubscriptionUpdated(_ data: [String: Any]) async {
        // Implementar lógica para assinatura atualizada
        print("Assinatura atualizada: \(data)")
    }
    
    private func handleSubscriptionDeleted(_ data: [String: Any]) async {
        // Implementar lógica para assinatura cancelada
        print("Assinatura cancelada: \(data)")
    }
    
    private func handleInvoicePaymentSucceeded(_ data: [String: Any]) async {
        // Implementar lógica para pagamento de fatura bem-sucedido
        print("Pagamento de fatura bem-sucedido: \(data)")
    }
    
    private func handleInvoicePaymentFailed(_ data: [String: Any]) async {
        // Implementar lógica para pagamento de fatura falhado
        print("Pagamento de fatura falhado: \(data)")
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    func formatAmount(_ amount: Decimal) -> Int {
        // Converter de reais para centavos
        return Int(amount * 100)
    }
    
    func formatAmountFromCents(_ cents: Int) -> Decimal {
        // Converter de centavos para reais
        return Decimal(cents) / 100
    }
}

// MARK: - Stripe Models
struct StripeCustomer: Codable {
    let id: String
    let email: String?
    let name: String?
    let created: Int
    let defaultSource: String?
    let metadata: [String: String]
}

struct StripeCustomerResponse: Codable {
    let id: String
    let object: String
    let email: String?
    let name: String?
}

struct StripePaymentMethod: Codable {
    let id: String
    let object: String
    let type: String
    let card: StripeCard?
    let created: Int
    let customer: String?
}

struct StripeCard: Codable {
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int
    let funding: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case brand, last4, funding, country
        case expMonth = "exp_month"
        case expYear = "exp_year"
    }
}

struct StripePaymentMethodResponse: Codable {
    let id: String
    let object: String
    let type: String
    let card: StripeCard?
}

struct StripePaymentMethodsResponse: Codable {
    let object: String
    let data: [StripePaymentMethod]
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case object, data
        case hasMore = "has_more"
    }
}

struct StripeSubscription: Codable {
    let id: String
    let object: String
    let status: String
    let currentPeriodStart: Int
    let currentPeriodEnd: Int
    let customer: String
    let items: StripeSubscriptionItems
    let latestInvoice: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, status, customer, items
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case latestInvoice = "latest_invoice"
    }
}

struct StripeSubscriptionItems: Codable {
    let object: String
    let data: [StripeSubscriptionItem]
}

struct StripeSubscriptionItem: Codable {
    let id: String
    let object: String
    let price: StripePrice
}

struct StripePrice: Codable {
    let id: String
    let object: String
    let unitAmount: Int?
    let currency: String
    let recurring: StripePriceRecurring?
    
    enum CodingKeys: String, CodingKey {
        case id, object, currency, recurring
        case unitAmount = "unit_amount"
    }
}

struct StripePriceRecurring: Codable {
    let interval: String
    let intervalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case interval
        case intervalCount = "interval_count"
    }
}

struct StripePaymentIntent: Codable {
    let id: String
    let object: String
    let amount: Int
    let currency: String
    let status: String
    let clientSecret: String?
    let customer: String?
    let paymentMethod: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, amount, currency, status, customer
        case clientSecret = "client_secret"
        case paymentMethod = "payment_method"
    }
}

struct StripeAccount: Codable {
    let id: String
    let object: String
    let type: String
    let country: String
    let email: String?
    let chargesEnabled: Bool
    let payoutsEnabled: Bool
    let detailsSubmitted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, object, type, country, email
        case chargesEnabled = "charges_enabled"
        case payoutsEnabled = "payouts_enabled"
        case detailsSubmitted = "details_submitted"
    }
}

struct StripeAccountResponse: Codable {
    let id: String
    let object: String
    let type: String
}

struct StripeAccountLink: Codable {
    let object: String
    let url: String
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case object, url
        case expiresAt = "expires_at"
    }
}

struct StripeAccountLinkResponse: Codable {
    let object: String
    let url: String
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case object, url
        case expiresAt = "expires_at"
    }
}

struct StripeTransfer: Codable {
    let id: String
    let object: String
    let amount: Int
    let currency: String
    let destination: String
    let created: Int
    let transferGroup: String?
    
    enum CodingKeys: String, CodingKey {
        case id, object, amount, currency, destination, created
        case transferGroup = "transfer_group"
    }
}

// MARK: - Stripe Errors
enum StripeError: LocalizedError {
    case invalidConfiguration
    case invalidCustomer
    case invalidPaymentMethod
    case invalidSubscription
    case paymentFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Configuração do Stripe inválida"
        case .invalidCustomer:
            return "Cliente inválido"
        case .invalidPaymentMethod:
            return "Método de pagamento inválido"
        case .invalidSubscription:
            return "Assinatura inválida"
        case .paymentFailed(let reason):
            return "Pagamento falhou: \(reason)"
        case .networkError(let message):
            return "Erro de rede: \(message)"
        }
    }
}
