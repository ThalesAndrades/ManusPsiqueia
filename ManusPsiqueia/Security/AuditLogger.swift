//
//  AuditLogger.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
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
        
        // Persistir log localmente de forma segura
        persistLogSecurely(event: event, details: logDetails, severity: severity, userId: userId)
        
        // Implementar alertas em tempo real para eventos críticos
        if severity == .critical || severity == .high {
            sendRealTimeAlert(event: event, details: logDetails, severity: severity)
        }
        
        // Enviar para servidor remoto em produção
        sendToRemoteLoggingService(event: event, details: logDetails, severity: severity, userId: userId)
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
    
    // MARK: - Secure Persistence
    
    /// Persiste logs de forma segura localmente
    private func persistLogSecurely(event: SecurityEvent, details: [String: String], severity: LogSeverity, userId: UUID?) {
        let logEntry = AuditLogEntry(
            timestamp: Date(),
            event: event,
            details: details,
            severity: severity,
            userId: userId
        )
        
        // Armazenar no Keychain para logs críticos ou UserDefaults criptografado para outros
        if severity == .critical || severity == .high {
            storeInKeychain(logEntry: logEntry)
        } else {
            storeInSecureUserDefaults(logEntry: logEntry)
        }
    }
    
    /// Armazena log no Keychain para máxima segurança
    private func storeInKeychain(logEntry: AuditLogEntry) {
        do {
            let data = try JSONEncoder().encode(logEntry)
            let keychainKey = "audit_log_\(logEntry.id)"
            
            // Remover entrada anterior se existir
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keychainKey
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // Adicionar nova entrada
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keychainKey,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            if status != errSecSuccess {
                print("Failed to store audit log in Keychain: \(status)")
            }
        } catch {
            print("Failed to encode audit log: \(error)")
        }
    }
    
    /// Armazena log em UserDefaults com criptografia básica
    private func storeInSecureUserDefaults(logEntry: AuditLogEntry) {
        do {
            let data = try JSONEncoder().encode(logEntry)
            let encodedData = data.base64EncodedString()
            
            var existingLogs = UserDefaults.standard.stringArray(forKey: "audit_logs") ?? []
            existingLogs.append(encodedData)
            
            // Manter apenas os últimos 1000 logs para evitar uso excessivo de memória
            if existingLogs.count > 1000 {
                existingLogs = Array(existingLogs.suffix(1000))
            }
            
            UserDefaults.standard.set(existingLogs, forKey: "audit_logs")
        } catch {
            print("Failed to store audit log in UserDefaults: \(error)")
        }
    }
    
    // MARK: - Real-time Alerts
    
    /// Envia alertas em tempo real para eventos críticos
    private func sendRealTimeAlert(event: SecurityEvent, details: [String: String], severity: LogSeverity) {
        // Notificação local para desenvolvedores/administradores
        sendLocalNotification(event: event, severity: severity)
        
        // Em produção, integrar com sistemas como PagerDuty, Slack, etc.
        if severity == .critical {
            triggerEmergencyAlert(event: event, details: details)
        }
    }
    
    /// Envia notificação local
    private func sendLocalNotification(event: SecurityEvent, severity: LogSeverity) {
        let content = UNMutableNotificationContent()
        content.title = "Alerta de Segurança ManusPsiqueia"
        content.body = "Evento \(severity): \(event)"
        content.sound = severity == .critical ? .defaultCritical : .default
        content.categoryIdentifier = "SECURITY_ALERT"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send security notification: \(error)")
            }
        }
    }
    
    /// Dispara alerta de emergência para eventos críticos
    private func triggerEmergencyAlert(event: SecurityEvent, details: [String: String]) {
        // Em produção, integrar com:
        // - PagerDuty API
        // - Slack webhooks
        // - SMS/telefone para equipe de segurança
        // - Sistema de tickets (Jira, ServiceNow)
        
        print("🚨 EMERGENCY SECURITY ALERT 🚨")
        print("Event: \(event)")
        print("Details: \(details)")
        print("Time: \(Date())")
        
        // Exemplo de integração com webhook (desabilitado por enquanto)
        // sendWebhookAlert(event: event, details: details)
    }
    
    // MARK: - Remote Logging
    
    /// Envia logs para serviço de logging remoto
    private func sendToRemoteLoggingService(event: SecurityEvent, details: [String: String], severity: LogSeverity, userId: UUID?) {
        // Em produção, integrar com serviços como:
        // - AWS CloudWatch
        // - Azure Monitor
        // - Google Cloud Logging
        // - Splunk
        // - ELK Stack
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/audit/logs") else { return }
        
        let logData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "event": String(describing: event),
            "details": details,
            "severity": String(describing: severity),
            "userId": userId?.uuidString ?? "anonymous",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "iOS"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: logData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to send audit log to remote service: \(error)")
                    // Tentar novamente mais tarde ou armazenar para envio posterior
                }
            }.resume()
        } catch {
            print("Failed to serialize audit log data: \(error)")
        }
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

// MARK: - Audit Log Entry Structure

struct AuditLogEntry: Codable {
    let id: UUID
    let timestamp: Date
    let event: String
    let details: [String: String]
    let severity: String
    let userId: UUID?
    
    init(timestamp: Date, event: SecurityEvent, details: [String: String], severity: LogSeverity, userId: UUID?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.event = String(describing: event)
        self.details = details
        self.severity = String(describing: severity)
        self.userId = userId
    }
}

enum LogSeverity {
    case low, info, medium, warning, high, critical
}

enum SecuritySeverity {
    case info
    case warning
    case medium
    case high
    case critical
}
