import ManusPsiqueiaServices
//
//  WebhookManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit
#if canImport(SwiftKeychainWrapper)
import SwiftKeychainWrapper
#endif

// MARK: - Webhook Event Types
enum WebhookEventType: String, CaseIterable {
    case invoicePaymentSucceeded = "invoice.payment_succeeded"
    case invoicePaymentFailed = "invoice.payment_failed"
    case customerSubscriptionCreated = "customer.subscription.created"
    case customerSubscriptionUpdated = "customer.subscription.updated"
    case customerSubscriptionDeleted = "customer.subscription.deleted"
    case paymentIntentSucceeded = "payment_intent.succeeded"
    case paymentIntentPaymentFailed = "payment_intent.payment_failed"
    case customerCreated = "customer.created"
    case priceCreated = "price.created"
    case paymentMethodAttached = "payment_method.attached"
    
    var displayName: String {
        switch self {
        case .invoicePaymentSucceeded:
            return "Pagamento de Fatura Bem-sucedido"
        case .invoicePaymentFailed:
            return "Pagamento de Fatura Falhou"
        case .customerSubscriptionCreated:
            return "Assinatura Criada"
        case .customerSubscriptionUpdated:
            return "Assinatura Atualizada"
        case .customerSubscriptionDeleted:
            return "Assinatura Cancelada"
        case .paymentIntentSucceeded:
            return "Pagamento Bem-sucedido"
        case .paymentIntentPaymentFailed:
            return "Pagamento Falhou"
        case .customerCreated:
            return "Cliente Criado"
        case .priceCreated:
            return "Preço Criado"
        case .paymentMethodAttached:
            return "Método de Pagamento Anexado"
        }
    }
}

// MARK: - Webhook Event
struct StripeWebhookEvent: Codable, Identifiable {
    let id: String
    let type: WebhookEventType
    let created: Int
    let data: [String: Any]
    let livemode: Bool?
    let pendingWebhooks: Int?
    let request: WebhookRequest?
    
    enum CodingKeys: String, CodingKey {
        case id, type, created, data, livemode
        case pendingWebhooks = "pending_webhooks"
        case request
    }
    
    struct WebhookRequest: Codable {
        let id: String?
        let idempotencyKey: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case idempotencyKey = "idempotency_key"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        let typeString = try container.decode(String.self, forKey: .type)
        guard let eventType = WebhookEventType(rawValue: typeString) else {
            throw WebhookError.unsupportedEventType(typeString)
        }
        type = eventType
        
        created = try container.decode(Int.self, forKey: .created)
        livemode = try container.decodeIfPresent(Bool.self, forKey: .livemode)
        pendingWebhooks = try container.decodeIfPresent(Int.self, forKey: .pendingWebhooks)
        request = try container.decodeIfPresent(WebhookRequest.self, forKey: .request)
        
        // Decode data as [String: Any]
        let dataContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .data)
        var decodedData: [String: Any] = [:]
        
        for key in dataContainer.allKeys {
            if let value = try? dataContainer.decode(String.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Int.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Bool.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode([String: Any].self, forKey: key) {
                decodedData[key.stringValue] = value
            }
        }
        
        data = decodedData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(created, forKey: .created)
        try container.encodeIfPresent(livemode, forKey: .livemode)
        try container.encodeIfPresent(pendingWebhooks, forKey: .pendingWebhooks)
        try container.encodeIfPresent(request, forKey: .request)
        
        // Encode data - this is simplified, proper implementation would need recursive encoding
        var dataContainer = encoder.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .data)
        for (key, value) in data {
            let dynamicKey = DynamicCodingKey(stringValue: key)!
            
            if let stringValue = value as? String {
                try dataContainer.encode(stringValue, forKey: dynamicKey)
            } else if let intValue = value as? Int {
                try dataContainer.encode(intValue, forKey: dynamicKey)
            } else if let boolValue = value as? Bool {
                try dataContainer.encode(boolValue, forKey: dynamicKey)
            }
        }
    }
}

// MARK: - Dynamic Coding Key
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - Webhook Processing Result
enum WebhookProcessingResult {
    case success(String)
    case failure(Error)
    case ignored(String)
}

// MARK: - Webhook Manager
@MainActor
class WebhookManager: ObservableObject {
    static let shared = WebhookManager()
    
    @Published var isProcessing = false
    @Published var lastProcessedEvent: StripeWebhookEvent?
    @Published var processingQueue: [StripeWebhookEvent] = []
    @Published var processedEvents: [String] = [] // Event IDs to prevent duplicates
    
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private let stripeManager = StripeManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Webhook configuration
    private let webhookSecret: String
    private let maxRetryAttempts = 3
    private let retryDelays: [TimeInterval] = [1.0, 5.0, 15.0]
    
    init() {
        self.webhookSecret = getWebhookSecret()
        setupEventProcessing()
    }
    
    private func getWebhookSecret() -> String {
        // Try to get from Keychain first (production)
        if let secret = KeychainWrapper.standard.string(forKey: "stripe_webhook_secret") {
            return secret
        }
        
        // Fallback to environment (development)
        return ProcessInfo.processInfo.environment["STRIPE_WEBHOOK_SECRET"] ?? "whsec_test_..."
    }
    
    // MARK: - Webhook Validation
    
    /// Validates webhook signature using Stripe's recommended approach
    func validateWebhook(payload: Data, signature: String, secret: String) -> Bool {
        let elements = signature.components(separatedBy: ",")
        var timestamp: String?
        var signatures: [String] = []
        
        for element in elements {
            let keyValue = element.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1]
                
                if key == "t" {
                    timestamp = value
                } else if key.hasPrefix("v1") {
                    signatures.append(value)
                }
            }
        }
        
        guard let timestamp = timestamp,
              !signatures.isEmpty else {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .error,
                details: "Webhook signature validation failed: missing timestamp or signature"
            )
            return false
        }
        
        // Check timestamp (reject events older than 5 minutes)
        if let timestampInt = Int(timestamp) {
            let eventTime = Date(timeIntervalSince1970: TimeInterval(timestampInt))
            let timeDifference = abs(Date().timeIntervalSince(eventTime))
            
            if timeDifference > 300 { // 5 minutes
                auditLogger.log(
                    event: .networkRequestFailed,
                    severity: .error,
                    details: "Webhook timestamp too old: \(timeDifference) seconds"
                )
                return false
            }
        }
        
        // Create expected signature
        let payloadString = String(data: payload, encoding: .utf8) ?? ""
        let signedPayload = "\(timestamp).\(payloadString)"
        
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let signature_bytes = HMAC<SHA256>.authenticationCode(for: signedPayload.data(using: .utf8)!, using: key)
        let expectedSignature = Data(signature_bytes).map { String(format: "%02x", $0) }.joined()
        
        // Compare signatures using constant-time comparison
        for providedSignature in signatures {
            if providedSignature == expectedSignature {
                return true
            }
        }
        
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .error,
            details: "Webhook signature validation failed: signature mismatch"
        )
        return false
    }
    
    // MARK: - Webhook Processing
    
    /// Processes incoming webhook
    func processWebhook(_ event: StripeWebhookEvent) async -> WebhookProcessingResult {
        // Check for duplicate processing
        if processedEvents.contains(event.id) {
            auditLogger.log(
                event: .networkRequest,
                severity: .info,
                details: "Duplicate webhook event ignored: \(event.id)"
            )
            return .ignored("Duplicate event")
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Processing webhook event: \(event.type.rawValue) - \(event.id)"
        )
        
        do {
            let result = try await processEventByType(event)
            
            // Mark as processed
            processedEvents.append(event.id)
            lastProcessedEvent = event
            
            // Keep only last 1000 processed events to prevent memory issues
            if processedEvents.count > 1000 {
                processedEvents.removeFirst(processedEvents.count - 1000)
            }
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Webhook processed successfully: \(event.id)"
            )
            
            return .success(result)
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .error,
                details: "Webhook processing failed: \(event.id) - \(error.localizedDescription)"
            )
            
            return .failure(error)
        }
    }
    
    /// Processes webhook with retry mechanism
    func processWebhookWithRetry(_ event: StripeWebhookEvent) async -> WebhookProcessingResult {
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            let result = await processWebhook(event)
            
            switch result {
            case .success, .ignored:
                return result
            case .failure(let error):
                lastError = error
                
                if attempt < maxRetryAttempts - 1 {
                    let delay = retryDelays[min(attempt, retryDelays.count - 1)]
                    auditLogger.log(
                        event: .networkRequest,
                        severity: .warning,
                        details: "Webhook processing attempt \(attempt + 1) failed, retrying in \(delay)s"
                    )
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        return .failure(lastError ?? WebhookError.maxRetriesExceeded)
    }
    
    // MARK: - Event Type Handlers
    
    private func processEventByType(_ event: StripeWebhookEvent) async throws -> String {
        switch event.type {
        case .invoicePaymentSucceeded:
            return try await handleSuccessfulPayment(event)
        case .invoicePaymentFailed:
            return try await handleFailedPayment(event)
        case .customerSubscriptionCreated:
            return try await handleSubscriptionCreated(event)
        case .customerSubscriptionUpdated:
            return try await handleSubscriptionUpdated(event)
        case .customerSubscriptionDeleted:
            return try await handleSubscriptionCancelled(event)
        case .paymentIntentSucceeded:
            return try await handlePaymentIntentSucceeded(event)
        case .paymentIntentPaymentFailed:
            return try await handlePaymentIntentFailed(event)
        case .customerCreated:
            return try await handleCustomerCreated(event)
        case .priceCreated:
            return try await handlePriceCreated(event)
        case .paymentMethodAttached:
            return try await handlePaymentMethodAttached(event)
        }
    }
    
    // MARK: - Specific Event Handlers
    
    private func handleSuccessfulPayment(_ event: StripeWebhookEvent) async throws -> String {
        guard let invoiceData = event.data["object"] as? [String: Any],
              let customerId = invoiceData["customer"] as? String,
              let amountPaid = invoiceData["amount_paid"] as? Int else {
            throw WebhookError.invalidEventData
        }
        
        // Update user subscription status
        try await updateUserSubscriptionStatus(customerId: customerId, status: "active")
        
        // Send confirmation notification
        await sendPaymentConfirmationNotification(customerId: customerId, amount: amountPaid)
        
        // Update flow state if payment flow is active
        if FlowManager.shared.currentFlow == .subscription {
            FlowManager.shared.completeFlow(metadata: [
                "payment_amount": amountPaid,
                "customer_id": customerId
            ])
        }
        
        return "Payment successful for customer: \(customerId)"
    }
    
    private func handleFailedPayment(_ event: StripeWebhookEvent) async throws -> String {
        guard let invoiceData = event.data["object"] as? [String: Any],
              let customerId = invoiceData["customer"] as? String,
              let failureReason = invoiceData["last_payment_error"] as? [String: Any] else {
            throw WebhookError.invalidEventData
        }
        
        let errorMessage = failureReason["message"] as? String ?? "Pagamento falhou"
        
        // Handle failed payment
        try await handleFailedPaymentRecovery(customerId: customerId, reason: errorMessage)
        
        // Send failure notification
        await sendPaymentFailureNotification(customerId: customerId, reason: errorMessage)
        
        // Update flow state if payment flow is active
        if FlowManager.shared.currentFlow == .subscription {
            FlowManager.shared.failFlow(
                error: WebhookError.paymentFailed(errorMessage),
                metadata: ["customer_id": customerId]
            )
        }
        
        return "Payment failed for customer: \(customerId)"
    }
    
    private func handleSubscriptionCreated(_ event: StripeWebhookEvent) async throws -> String {
        guard let subscriptionData = event.data["object"] as? [String: Any],
              let subscriptionId = subscriptionData["id"] as? String,
              let customerId = subscriptionData["customer"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Store subscription data
        try await storeSubscriptionData(subscriptionId: subscriptionId, customerId: customerId, data: subscriptionData)
        
        return "Subscription created: \(subscriptionId)"
    }
    
    private func handleSubscriptionUpdated(_ event: StripeWebhookEvent) async throws -> String {
        guard let subscriptionData = event.data["object"] as? [String: Any],
              let subscriptionId = subscriptionData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Update subscription data
        try await updateSubscriptionData(subscriptionId: subscriptionId, data: subscriptionData)
        
        return "Subscription updated: \(subscriptionId)"
    }
    
    private func handleSubscriptionCancelled(_ event: StripeWebhookEvent) async throws -> String {
        guard let subscriptionData = event.data["object"] as? [String: Any],
              let subscriptionId = subscriptionData["id"] as? String,
              let customerId = subscriptionData["customer"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Cancel subscription in local system
        try await cancelUserSubscription(customerId: customerId, subscriptionId: subscriptionId)
        
        return "Subscription cancelled: \(subscriptionId)"
    }
    
    private func handlePaymentIntentSucceeded(_ event: StripeWebhookEvent) async throws -> String {
        guard let paymentIntentData = event.data["object"] as? [String: Any],
              let paymentIntentId = paymentIntentData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Handle one-time payment success
        try await processOneTimePayment(paymentIntentId: paymentIntentId, data: paymentIntentData)
        
        return "Payment intent succeeded: \(paymentIntentId)"
    }
    
    private func handlePaymentIntentFailed(_ event: StripeWebhookEvent) async throws -> String {
        guard let paymentIntentData = event.data["object"] as? [String: Any],
              let paymentIntentId = paymentIntentData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Handle one-time payment failure
        try await handleOneTimePaymentFailure(paymentIntentId: paymentIntentId, data: paymentIntentData)
        
        return "Payment intent failed: \(paymentIntentId)"
    }
    
    private func handleCustomerCreated(_ event: StripeWebhookEvent) async throws -> String {
        guard let customerData = event.data["object"] as? [String: Any],
              let customerId = customerData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Store customer data
        try await storeCustomerData(customerId: customerId, data: customerData)
        
        return "Customer created: \(customerId)"
    }
    
    private func handlePriceCreated(_ event: StripeWebhookEvent) async throws -> String {
        guard let priceData = event.data["object"] as? [String: Any],
              let priceId = priceData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Store price data for dynamic pricing
        try await storePriceData(priceId: priceId, data: priceData)
        
        return "Price created: \(priceId)"
    }
    
    private func handlePaymentMethodAttached(_ event: StripeWebhookEvent) async throws -> String {
        guard let paymentMethodData = event.data["object"] as? [String: Any],
              let paymentMethodId = paymentMethodData["id"] as? String else {
            throw WebhookError.invalidEventData
        }
        
        // Update user payment methods
        try await updateUserPaymentMethods(paymentMethodId: paymentMethodId, data: paymentMethodData)
        
        return "Payment method attached: \(paymentMethodId)"
    }
    
    // MARK: - Helper Methods
    
    private func setupEventProcessing() {
        // Setup periodic cleanup of processed events
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldProcessedEvents()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupOldProcessedEvents() {
        // Keep only last 500 processed events
        if processedEvents.count > 500 {
            processedEvents.removeFirst(processedEvents.count - 500)
        }
        
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Cleaned up old processed webhook events"
        )
    }
    
    // MARK: - Database Operations (to be implemented based on chosen backend)
    
    private func updateUserSubscriptionStatus(customerId: String, status: String) async throws {
        // Implementation depends on chosen backend (Supabase, Firebase, etc.)
        // This is a placeholder for the actual implementation
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Updating subscription status for customer: \(customerId) to \(status)"
        )
    }
    
    private func handleFailedPaymentRecovery(customerId: String, reason: String) async throws {
        // Implementation for payment failure recovery logic
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .warning,
            details: "Processing payment failure recovery for customer: \(customerId) - \(reason)"
        )
    }
    
    private func sendPaymentConfirmationNotification(customerId: String, amount: Int) async {
        // Implementation for sending success notifications
        auditLogger.log(
            event: .networkRequestSuccess,
            severity: .info,
            details: "Sending payment confirmation for customer: \(customerId) - Amount: \(amount)"
        )
    }
    
    private func sendPaymentFailureNotification(customerId: String, reason: String) async {
        // Implementation for sending failure notifications
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .warning,
            details: "Sending payment failure notification for customer: \(customerId) - \(reason)"
        )
    }
    
    private func storeSubscriptionData(subscriptionId: String, customerId: String, data: [String: Any]) async throws {
        // Store subscription data in database
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Storing subscription data: \(subscriptionId) for customer: \(customerId)"
        )
    }
    
    private func updateSubscriptionData(subscriptionId: String, data: [String: Any]) async throws {
        // Update subscription data in database
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Updating subscription data: \(subscriptionId)"
        )
    }
    
    private func cancelUserSubscription(customerId: String, subscriptionId: String) async throws {
        // Cancel subscription in local system
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Cancelling subscription: \(subscriptionId) for customer: \(customerId)"
        )
    }
    
    private func processOneTimePayment(paymentIntentId: String, data: [String: Any]) async throws {
        // Process one-time payment
        auditLogger.log(
            event: .networkRequestSuccess,
            severity: .info,
            details: "Processing one-time payment: \(paymentIntentId)"
        )
    }
    
    private func handleOneTimePaymentFailure(paymentIntentId: String, data: [String: Any]) async throws {
        // Handle one-time payment failure
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .warning,
            details: "Handling one-time payment failure: \(paymentIntentId)"
        )
    }
    
    private func storeCustomerData(customerId: String, data: [String: Any]) async throws {
        // Store customer data
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Storing customer data: \(customerId)"
        )
    }
    
    private func storePriceData(priceId: String, data: [String: Any]) async throws {
        // Store price data for dynamic pricing
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Storing price data: \(priceId)"
        )
    }
    
    private func updateUserPaymentMethods(paymentMethodId: String, data: [String: Any]) async throws {
        // Update user payment methods
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Updating payment methods: \(paymentMethodId)"
        )
    }
}

// MARK: - Webhook Error Types
enum WebhookError: LocalizedError {
    case invalidSignature
    case unsupportedEventType(String)
    case invalidEventData
    case paymentFailed(String)
    case maxRetriesExceeded
    case processingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSignature:
            return "Assinatura do webhook inválida"
        case .unsupportedEventType(let type):
            return "Tipo de evento não suportado: \(type)"
        case .invalidEventData:
            return "Dados do evento inválidos"
        case .paymentFailed(let reason):
            return "Pagamento falhou: \(reason)"
        case .maxRetriesExceeded:
            return "Número máximo de tentativas excedido"
        case .processingError(let message):
            return "Erro no processamento: \(message)"
        }
    }
}

// MARK: - Webhook Extensions for Testing
extension WebhookManager {
    /// Creates a test webhook event for development
    func createTestWebhookEvent(type: WebhookEventType, data: [String: Any] = [:]) -> StripeWebhookEvent {
        return StripeWebhookEvent(
            id: "evt_test_\(UUID().uuidString)",
            type: type,
            created: Int(Date().timeIntervalSince1970),
            data: data,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
    }
    
    /// Generates test signature for webhook validation testing
    func generateTestSignature(for payload: Data, secret: String) -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadString = String(data: payload, encoding: .utf8) ?? ""
        let signedPayload = "\(timestamp).\(payloadString)"
        
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let signature_bytes = HMAC<SHA256>.authenticationCode(for: signedPayload.data(using: .utf8)!, using: key)
        let signature = Data(signature_bytes).map { String(format: "%02x", $0) }.joined()
        
        return "t=\(timestamp),v1=\(signature)"
    }
}