//
//  AuditLogger.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import Security

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
        
        // Implementar persistência segura do log
        persistLogSecurely(logEntry: logEntry)
        
        // Implementar alertas em tempo real para eventos críticos
        if severity == .critical || severity == .high {
            sendRealTimeAlert(for: logEntry)
        }
    }
    
    /// Persiste o log de forma segura usando Keychain para dados sensíveis
    /// - Parameter logEntry: A entrada do log para persistir
    private func persistLogSecurely(logEntry: AuditLogEntry) {
        // Para logs críticos, armazenar no Keychain
        if logEntry.severity == .critical {
            let keychainKey = "audit_log_\(logEntry.timestamp.timeIntervalSince1970)"
            do {
                let logData = try JSONEncoder().encode(logEntry)
                let status = SecItemAdd([
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: keychainKey,
                    kSecAttrService: "ManusPsiqueia.AuditLog",
                    kSecValueData: logData,
                    kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ] as CFDictionary, nil)
                
                if status != errSecSuccess {
                    print("Falha ao salvar log crítico no Keychain: \(status)")
                }
            } catch {
                print("Erro ao codificar log para Keychain: \(error)")
            }
        }
        
        // Para outros logs, armazenar em UserDefaults com limite de tamanho
        var existingLogs = UserDefaults.standard.array(forKey: "audit_logs") as? [[String: Any]] ?? []
        
        // Converter entrada do log para dicionário
        if let logData = try? JSONEncoder().encode(logEntry),
           let logDict = try? JSONSerialization.jsonObject(with: logData) as? [String: Any] {
            existingLogs.append(logDict)
            
            // Manter apenas os últimos 1000 logs para evitar uso excessivo de memória
            if existingLogs.count > 1000 {
                existingLogs = Array(existingLogs.suffix(1000))
            }
            
            UserDefaults.standard.set(existingLogs, forKey: "audit_logs")
        }
    }
    
    /// Envia alertas em tempo real para eventos críticos
    /// - Parameter logEntry: A entrada do log que acionou o alerta
    private func sendRealTimeAlert(for logEntry: AuditLogEntry) {
        // 1. Notificação local imediata
        let content = UNMutableNotificationContent()
        content.title = "Alerta de Segurança"
        content.body = "Evento crítico detectado: \(logEntry.event.rawValue)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "SECURITY_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "security_\(logEntry.timestamp.timeIntervalSince1970)",
            content: content,
            trigger: nil // Imediato
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao enviar notificação de segurança: \(error)")
            }
        }
        
        // 2. Log estruturado para monitoramento externo
        let alertPayload: [String: Any] = [
            "app": "ManusPsiqueia",
            "alert_type": "security_event",
            "severity": logEntry.severity.rawValue,
            "event": logEntry.event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: logEntry.timestamp),
            "details": logEntry.details,
            "user_id": logEntry.userId?.uuidString ?? "anonymous",
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
        
        // Em produção, enviar para serviço de monitoramento (Datadog, New Relic, etc.)
        print("CRITICAL_SECURITY_ALERT: \(alertPayload)")
        
        // 3. Para eventos extremamente críticos, notificar equipe de segurança
        if logEntry.severity == .critical {
            notifySecurityTeam(alert: alertPayload)
        }
    }
    
    /// Notifica a equipe de segurança sobre eventos críticos
    /// - Parameter alert: Dados do alerta para enviar
    private func notifySecurityTeam(alert: [String: Any]) {
        // Em produção, integrar com:
        // - Slack webhook para notificações imediatas
        // - Email para a equipe de segurança
        // - PagerDuty para incidentes críticos
        // - Sistema de ticketing (Jira, ServiceNow)
        
        print("🚨 NOTIFICAÇÃO EQUIPE SEGURANÇA: \(alert)")
        
        // Exemplo de implementação para webhook do Slack (desabilitado para desenvolvimento)
        /*
        Task {
            do {
                guard let url = URL(string: SecurityConfiguration.slackWebhookURL) else { return }
                
                let slackPayload = [
                    "text": "🚨 Alerta Crítico de Segurança - ManusPsiqueia",
                    "attachments": [
                        [
                            "color": "danger",
                            "fields": [
                                ["title": "Evento", "value": alert["event"] ?? "N/A", "short": true],
                                ["title": "Severidade", "value": alert["severity"] ?? "N/A", "short": true],
                                ["title": "Timestamp", "value": alert["timestamp"] ?? "N/A", "short": false]
                            ]
                        ]
                    ]
                ]
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: slackPayload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                print("Slack notification sent: \(response)")
            } catch {
                print("Erro ao enviar notificação Slack: \(error)")
            }
        }
        */
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
}

enum SecuritySeverity {
    case info
    case warning
    case medium
    case high
    case critical
}
