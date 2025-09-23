//
//  AuditLogger.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation

/// Logger de auditoria para registrar eventos de segurança e compliance
/// Garante rastreabilidade e conformidade com LGPD, HIPAA, ISO 27001
final class AuditLogger {
    
    static let shared = AuditLogger()
    
    private init() {
        // Configurar sistema de log persistente (e.g., Core Data, Realm, ou servidor remoto)
        // Para fins de demonstração, usaremos print
    }
    
    /// Registra um evento de auditoria
    /// - Parameters:
    ///   - event: Tipo do evento de segurança
    ///   - details: Dicionário com detalhes adicionais do evento
    ///   - severity: Nível de severidade do evento
    ///   - userId: ID do usuário associado ao evento (se aplicável)
    func log(
        event: SecurityEvent,
        details: [String: Any] = [:],
        severity: SecuritySeverity,
        userId: UUID? = nil
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let eventId = UUID().uuidString
        
        var logDetails: [String: Any] = [
            "timestamp": timestamp,
            "event_id": eventId,
            "event_type": String(describing: event),
            "severity": String(describing: severity),
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        if let userId = userId {
            logDetails["user_id"] = userId.uuidString
        }
        
        details.forEach { (key, value) in
            logDetails[key] = value
        }
        
        // Em um ambiente de produção, este log seria enviado para um SIEM (Security Information and Event Management)
        // ou um sistema de log centralizado e seguro.
        print("AUDIT LOG [\(severity)] - \(event): \(logDetails)")
        
        // TODO: Implementar persistência segura do log (e.g., Core Data criptografado, ou envio para servidor remoto)
        // TODO: Implementar alertas em tempo real para eventos críticos
    }
    
    /// Registra uma tentativa de acesso não autorizado
    func logUnauthorizedAccess(userId: UUID? = nil, ipAddress: String? = nil, reason: String) {
        log(
            event: .unauthorizedAccessAttempt,
            details: ["ip_address": ipAddress ?? "Unknown", "reason": reason],
            severity: .critical,
            userId: userId
        )
    }
    
    /// Registra uma falha de autenticação
    func logAuthenticationFailure(email: String, reason: String) {
        log(
            event: .authenticationFailure,
            details: ["email": email, "reason": reason],
            severity: .warning
        )
    }
    
    /// Registra acesso a dados sensíveis
    func logSensitiveDataAccess(userId: UUID, dataType: String, accessType: String) {
        log(
            event: .sensitiveDataAccess,
            details: ["data_type": dataType, "access_type": accessType],
            severity: .info,
            userId: userId
        )
    }
}

enum SecurityEvent {
    case authenticationSuccess
    case authenticationFailure
    case unauthorizedAccessAttempt
    case sensitiveDataAccess
    case dataModification
    case dataDeletion
    case certificateValidation
    case certificateValidationSuccess
    case certificateValidationFailed
    case certificatePinAdded
    case certificatePinRemoved
    case certificateUpdateStarted
    case certificateUpdateCompleted
    case certificateUpdateAttempted
    case certificateUpdateFailed
    case deviceCompromised
    case debuggingDetected
    case suspiciousNetwork
    case emergencyBypass
    case securityPolicyViolation
    case systemError
    case logout
    case profileUpdate
    case configurationChange
    case userConsentGranted
    case userConsentRevoked
    case paymentProcessed
    case subscriptionCreated
    case subscriptionUpdated
    case subscriptionCanceled
    case withdrawalProcessed
    case aiAnalysisRequest
    case aiInsightGenerated
    case dataAnonymized
    case dataEncrypted
    case dataDecrypted
    case dataRetentionPolicyApplied
    case securityIncidentReported
    case securityEmergencyReported
    case securityIncidentUpdated
    case networkRequest
    case networkRequestSuccess
    case networkRequestFailed
    case securityValidationCompleted
    case securityValidationFailed
}

enum SecuritySeverity {
    case info
    case warning
    case medium
    case high
    case critical
}
