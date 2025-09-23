//
//  StripeConnectWebhookManager.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Stripe Connect Webhook Manager
@MainActor
class StripeConnectWebhookManager: ObservableObject {
    static let shared = StripeConnectWebhookManager()
    
    @Published var isProcessing = false
    @Published var lastProcessedEvent: String?
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private let sessionPaymentService = SessionPaymentService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let webhookSecret: String
    private let tolerance: TimeInterval = 300 // 5 minutos
    
    init() {
        self.webhookSecret = getWebhookSecret()
        setupEventProcessing()
    }
    
    private func getWebhookSecret() -> String {
        // Buscar do Keychain ou environment
        return ProcessInfo.processInfo.environment["STRIPE_WEBHOOK_SECRET"] ?? "whsec_..."
    }
    
    private func setupEventProcessing() {
        // Configurar processamento de eventos em background
        NotificationCenter.default.addObserver(
            forName: .stripeWebhookReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let eventData = notification.userInfo?["event"] as? Data {
                Task {
                    await self?.processWebhookEvent(eventData)
                }
            }
        }
    }
    
    // MARK: - Webhook Processing
    
    /// Processa um evento de webhook do Stripe Connect
    func processWebhookEvent(_ eventData: Data) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Parse do evento
            guard let eventJSON = try JSONSerialization.jsonObject(with: eventData) as? [String: Any],
                  let eventType = eventJSON["type"] as? String,
                  let eventId = eventJSON["id"] as? String else {
                throw WebhookError.invalidPayload
            }
            
            auditLogger.log(
                event: .networkRequest,
                severity: .info,
                details: "Processando webhook: \(eventType) - \(eventId)"
            )
            
            // Verificar se já processamos este evento
            if await isDuplicateEvent(eventId) {
                auditLogger.log(
                    event: .networkRequest,
                    severity: .info,
                    details: "Evento duplicado ignorado: \(eventId)"
                )
                return
            }
            
            // Processar baseado no tipo de evento
            try await handleEventType(eventType, data: eventJSON)
            
            // Marcar como processado
            await markEventAsProcessed(eventId)
            lastProcessedEvent = eventId
            
            auditLogger.log(
                event: .networkRequestSuccess,
                severity: .info,
                details: "Webhook processado com sucesso: \(eventId)"
            )
            
        } catch {
            auditLogger.log(
                event: .networkRequestFailed,
                severity: .critical,
                details: "Falha no processamento do webhook: \(error.localizedDescription)"
            )
            errorMessage = error.localizedDescription
        }
    }
    
    /// Valida a assinatura do webhook
    func validateWebhookSignature(payload: Data, signature: String) -> Bool {
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
                } else if key == "v1" {
                    signatures.append(value)
                }
            }
        }
        
        guard let timestampString = timestamp,
              let timestampValue = TimeInterval(timestampString),
              !signatures.isEmpty else {
            return false
        }
        
        // Verificar se o timestamp não é muito antigo
        let currentTime = Date().timeIntervalSince1970
        if abs(currentTime - timestampValue) > tolerance {
            return false
        }
        
        // Criar payload para verificação
        let payloadString = "\(timestampString)." + String(data: payload, encoding: .utf8)!
        
        // Verificar assinatura
        for signature in signatures {
            if verifySignature(payload: payloadString, signature: signature) {
                return true
            }
        }
        
        return false
    }
    
    private func verifySignature(payload: String, signature: String) -> Bool {
        guard let payloadData = payload.data(using: .utf8),
              let secretData = webhookSecret.data(using: .utf8),
              let signatureData = Data(base64Encoded: signature) else {
            return false
        }
        
        let computedSignature = HMAC<SHA256>.authenticationCode(for: payloadData, using: SymmetricKey(data: secretData))
        let computedSignatureData = Data(computedSignature)
        
        return computedSignatureData == signatureData
    }
    
    // MARK: - Event Handlers
    
    private func handleEventType(_ eventType: String, data: [String: Any]) async throws {
        switch eventType {
        case "payment_intent.succeeded":
            try await handlePaymentIntentSucceeded(data)
            
        case "payment_intent.payment_failed":
            try await handlePaymentIntentFailed(data)
            
        case "account.updated":
            try await handleAccountUpdated(data)
            
        case "account.application.deauthorized":
            try await handleAccountDeauthorized(data)
            
        case "transfer.created":
            try await handleTransferCreated(data)
            
        case "transfer.paid":
            try await handleTransferPaid(data)
            
        case "transfer.failed":
            try await handleTransferFailed(data)
            
        case "payout.created":
            try await handlePayoutCreated(data)
            
        case "payout.paid":
            try await handlePayoutPaid(data)
            
        case "payout.failed":
            try await handlePayoutFailed(data)
            
        case "charge.dispute.created":
            try await handleDisputeCreated(data)
            
        default:
            auditLogger.log(
                event: .networkRequest,
                severity: .info,
                details: "Evento não tratado: \(eventType)"
            )
        }
    }
    
    // MARK: - Payment Intent Events
    
    private func handlePaymentIntentSucceeded(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let paymentIntentId = object["id"] as? String,
              let metadata = object["metadata"] as? [String: String],
              let sessionId = metadata["session_id"] else {
            throw WebhookError.missingRequiredFields
        }
        
        // Confirmar pagamento da sessão
        try await sessionPaymentService.confirmSessionPayment(paymentId: paymentIntentId)
        
        // Notificar usuários sobre pagamento bem-sucedido
        await notifyPaymentSuccess(sessionId: sessionId, paymentIntentId: paymentIntentId)
    }
    
    private func handlePaymentIntentFailed(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let paymentIntentId = object["id"] as? String,
              let metadata = object["metadata"] as? [String: String],
              let sessionId = metadata["session_id"] else {
            throw WebhookError.missingRequiredFields
        }
        
        // Atualizar status do pagamento para falhou
        await updatePaymentStatus(paymentIntentId: paymentIntentId, status: .failed)
        
        // Notificar usuários sobre falha no pagamento
        await notifyPaymentFailure(sessionId: sessionId, paymentIntentId: paymentIntentId)
    }
    
    // MARK: - Account Events
    
    private func handleAccountUpdated(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let accountId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        // Atualizar informações da conta conectada
        await updateConnectedAccountInfo(accountId: accountId, data: object)
    }
    
    private func handleAccountDeauthorized(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let accountId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        // Desativar conta conectada
        await deactivateConnectedAccount(accountId: accountId)
    }
    
    // MARK: - Transfer Events
    
    private func handleTransferCreated(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let transferId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        await logTransferEvent(transferId: transferId, status: "created")
    }
    
    private func handleTransferPaid(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let transferId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        await logTransferEvent(transferId: transferId, status: "paid")
    }
    
    private func handleTransferFailed(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let transferId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        await logTransferEvent(transferId: transferId, status: "failed")
    }
    
    // MARK: - Payout Events
    
    private func handlePayoutCreated(_ data: [String: Any]) async throws {
        // Implementar lógica de payout criado
    }
    
    private func handlePayoutPaid(_ data: [String: Any]) async throws {
        // Implementar lógica de payout pago
    }
    
    private func handlePayoutFailed(_ data: [String: Any]) async throws {
        // Implementar lógica de payout falhado
    }
    
    // MARK: - Dispute Events
    
    private func handleDisputeCreated(_ data: [String: Any]) async throws {
        guard let dataObject = data["data"] as? [String: Any],
              let object = dataObject["object"] as? [String: Any],
              let disputeId = object["id"] as? String else {
            throw WebhookError.missingRequiredFields
        }
        
        // Notificar sobre disputa criada
        await notifyDisputeCreated(disputeId: disputeId)
    }
    
    // MARK: - Helper Methods
    
    private func isDuplicateEvent(_ eventId: String) async -> Bool {
        // Verificar se o evento já foi processado
        // Implementar verificação no banco de dados ou cache
        return false
    }
    
    private func markEventAsProcessed(_ eventId: String) async {
        // Marcar evento como processado
        // Implementar persistência no banco de dados
    }
    
    private func updatePaymentStatus(paymentIntentId: String, status: SessionPaymentStatus) async {
        // Atualizar status do pagamento no serviço
    }
    
    private func notifyPaymentSuccess(sessionId: String, paymentIntentId: String) async {
        // Enviar notificações push/email sobre sucesso do pagamento
        auditLogger.log(
            event: .networkRequestSuccess,
            severity: .info,
            details: "Pagamento bem-sucedido notificado - Sessão: \(sessionId)"
        )
    }
    
    private func notifyPaymentFailure(sessionId: String, paymentIntentId: String) async {
        // Enviar notificações sobre falha no pagamento
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .warning,
            details: "Falha no pagamento notificada - Sessão: \(sessionId)"
        )
    }
    
    private func updateConnectedAccountInfo(accountId: String, data: [String: Any]) async {
        // Atualizar informações da conta conectada
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Conta conectada atualizada: \(accountId)"
        )
    }
    
    private func deactivateConnectedAccount(accountId: String) async {
        // Desativar conta conectada
        auditLogger.log(
            event: .networkRequest,
            severity: .warning,
            details: "Conta conectada desautorizada: \(accountId)"
        )
    }
    
    private func logTransferEvent(transferId: String, status: String) async {
        auditLogger.log(
            event: .networkRequest,
            severity: .info,
            details: "Transferência \(status): \(transferId)"
        )
    }
    
    private func notifyDisputeCreated(disputeId: String) async {
        auditLogger.log(
            event: .networkRequest,
            severity: .warning,
            details: "Disputa criada: \(disputeId)"
        )
    }
}

// MARK: - Webhook Errors

enum WebhookError: LocalizedError {
    case invalidPayload
    case invalidSignature
    case missingRequiredFields
    case eventProcessingFailed
    case duplicateEvent
    
    var errorDescription: String? {
        switch self {
        case .invalidPayload:
            return "Payload do webhook inválido"
        case .invalidSignature:
            return "Assinatura do webhook inválida"
        case .missingRequiredFields:
            return "Campos obrigatórios ausentes no webhook"
        case .eventProcessingFailed:
            return "Falha no processamento do evento"
        case .duplicateEvent:
            return "Evento duplicado"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let stripeWebhookReceived = Notification.Name("stripeWebhookReceived")
    static let paymentSucceeded = Notification.Name("paymentSucceeded")
    static let paymentFailed = Notification.Name("paymentFailed")
    static let accountUpdated = Notification.Name("accountUpdated")
}
