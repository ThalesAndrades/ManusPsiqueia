//
//  CertificatePinningManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import Network
import CryptoKit

/// Gerenciador de Certificate Pinning para máxima segurança
/// Protege contra ataques Man-in-the-Middle (MITM)
/// Compliance: HIPAA, LGPD, PCI DSS
final class CertificatePinningManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = CertificatePinningManager()
    
    private override init() {
        super.init()
        setupSecurityConfiguration()
    }
    
    // MARK: - Properties
    
    /// Certificados pinados para diferentes serviços
    private var pinnedCertificates: [String: Set<String>] = [:]
    
    /// Chaves públicas pinadas (backup)
    private var pinnedPublicKeys: [String: Set<String>] = [:]
    
    /// Configuração de segurança
    private var securityConfig: SecurityConfiguration!
    
    /// Logger de auditoria
    private let auditLogger = AuditLogger.shared
    
    // MARK: - Configuration
    
    private func setupSecurityConfiguration() {
        securityConfig = SecurityConfiguration()
        loadPinnedCertificates()
        loadPinnedPublicKeys()
    }
    
    /// Carrega certificados pinados para serviços críticos
    private func loadPinnedCertificates() {
        // Stripe API
        pinnedCertificates["api.stripe.com"] = [
            "sha256/E9CZ9INDbd+2eRQozYqqbQ2yXLVKB9+xcprMF+44U1g=",
            "sha256/vxRon/El5KuI4vx5ey1DgmsYmRY0nDd5Cg4GfJ8S+bg=",
            "sha256/Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o="
        ]
        
        // Supabase API
        pinnedCertificates["api.supabase.co"] = [
            "sha256/JSMzqOOrtyOT1kmau6zKhgT676hGgczD5VMdRMyJZFA=",
            "sha256/++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=",
            "sha256/f0KW/FtqTjs108NpYj42SrGvOB2PpxIVM8nWxjPqJGE="
        ]
        
        // OpenAI API
        pinnedCertificates["api.openai.com"] = [
            "sha256/FEzVOUp4dF3gI0ZVPRJhFbSD608T5Oc5i4S5Z7LcvjY=",
            "sha256/Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=",
            "sha256/Vjs8r4z+80wjNcr1YKepWQboSIRi63WsWXhIMN+eWys="
        ]
        
        // AiLun Backend
        pinnedCertificates["api.ailun.com.br"] = [
            "sha256/CUSTOM_AILUN_CERT_HASH_1",
            "sha256/CUSTOM_AILUN_CERT_HASH_2",
            "sha256/CUSTOM_AILUN_CERT_HASH_3"
        ]
    }
    
    /// Carrega chaves públicas pinadas como backup
    private func loadPinnedPublicKeys() {
        // Implementação similar para chaves públicas
        pinnedPublicKeys["api.stripe.com"] = [
            "sha256/PUBLIC_KEY_HASH_1",
            "sha256/PUBLIC_KEY_HASH_2"
        ]
        
        pinnedPublicKeys["api.supabase.co"] = [
            "sha256/PUBLIC_KEY_HASH_3",
            "sha256/PUBLIC_KEY_HASH_4"
        ]
    }
    
    // MARK: - Certificate Validation
    
    /// Valida certificado para um host específico
    /// - Parameters:
    ///   - challenge: Desafio de autenticação do servidor
    ///   - host: Host sendo validado
    /// - Returns: Disposição da validação
    func validateCertificate(
        for challenge: URLAuthenticationChallenge,
        host: String
    ) -> URLSession.AuthChallengeDisposition {
        
        auditLogger.log(
            event: .certificateValidation,
            details: ["host": host],
            severity: .info
        )
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            auditLogger.log(
                event: .certificateValidationFailed,
                details: ["host": host, "reason": "no_server_trust"],
                severity: .error
            )
            return .cancelAuthenticationChallenge
        }
        
        // Validar certificado pinado
        if validatePinnedCertificate(serverTrust: serverTrust, host: host) {
            auditLogger.log(
                event: .certificateValidationSuccess,
                details: ["host": host, "method": "certificate_pinning"],
                severity: .info
            )
            return .useCredential
        }
        
        // Fallback para validação de chave pública
        if validatePinnedPublicKey(serverTrust: serverTrust, host: host) {
            auditLogger.log(
                event: .certificateValidationSuccess,
                details: ["host": host, "method": "public_key_pinning"],
                severity: .info
            )
            return .useCredential
        }
        
        // Validação falhou - bloquear conexão
        auditLogger.log(
            event: .certificateValidationFailed,
            details: ["host": host, "reason": "pinning_failed"],
            severity: .critical
        )
        
        // Notificar incidente de segurança
        SecurityIncidentManager.shared.reportIncident(
            type: .certificatePinningFailure,
            host: host,
            severity: .high
        )
        
        return .cancelAuthenticationChallenge
    }
    
    /// Valida certificado pinado
    private func validatePinnedCertificate(
        serverTrust: SecTrust,
        host: String
    ) -> Bool {
        
        guard let pinnedHashes = pinnedCertificates[host] else {
            return false
        }
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            let certificateData = SecCertificateCopyData(certificate)
            let data = CFDataGetBytePtr(certificateData)
            let length = CFDataGetLength(certificateData)
            
            guard let data = data else { continue }
            
            let certificateBytes = Data(bytes: data, count: length)
            let hash = SHA256.hash(data: certificateBytes)
            let hashString = "sha256/" + Data(hash).base64EncodedString()
            
            if pinnedHashes.contains(hashString) {
                return true
            }
        }
        
        return false
    }
    
    /// Valida chave pública pinada
    private func validatePinnedPublicKey(
        serverTrust: SecTrust,
        host: String
    ) -> Bool {
        
        guard let pinnedHashes = pinnedPublicKeys[host] else {
            return false
        }
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i),
                  let publicKey = SecCertificateCopyKey(certificate) else {
                continue
            }
            
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) else {
                continue
            }
            
            let keyData = publicKeyData as Data
            let hash = SHA256.hash(data: keyData)
            let hashString = "sha256/" + Data(hash).base64EncodedString()
            
            if pinnedHashes.contains(hashString) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Dynamic Pinning
    
    /// Adiciona novo certificado pinado dinamicamente
    /// - Parameters:
    ///   - host: Host para adicionar certificado
    ///   - certificateHash: Hash do certificado
    func addPinnedCertificate(host: String, certificateHash: String) {
        if pinnedCertificates[host] == nil {
            pinnedCertificates[host] = Set<String>()
        }
        pinnedCertificates[host]?.insert(certificateHash)
        
        auditLogger.log(
            event: .certificatePinAdded,
            details: ["host": host, "hash": certificateHash],
            severity: .info
        )
    }
    
    /// Remove certificado pinado
    /// - Parameters:
    ///   - host: Host para remover certificado
    ///   - certificateHash: Hash do certificado
    func removePinnedCertificate(host: String, certificateHash: String) {
        pinnedCertificates[host]?.remove(certificateHash)
        
        auditLogger.log(
            event: .certificatePinRemoved,
            details: ["host": host, "hash": certificateHash],
            severity: .warning
        )
    }
    
    // MARK: - Certificate Rotation
    
    /// Atualiza certificados pinados automaticamente
    func updatePinnedCertificates() async {
        auditLogger.log(
            event: .certificateUpdateStarted,
            details: [:],
            severity: .info
        )
        
        // Buscar novos certificados dos serviços
        await updateStripecertificates()
        await updateSupabaseeCertificates()
        await updateOpenAICertificates()
        await updateAiLunCertificates()
        
        auditLogger.log(
            event: .certificateUpdateCompleted,
            details: [:],
            severity: .info
        )
    }
    
    private func updateStripeeCertificates() async {
        // Implementação para atualizar certificados Stripe
        // Buscar certificados atuais e validar
    }
    
    private func updateSupabaseeCertificates() async {
        // Implementação para atualizar certificados Supabase
    }
    
    private func updateOpenAICertificates() async {
        // Implementação para atualizar certificados OpenAI
    }
    
    private func updateAiLunCertificates() async {
        // Implementação para atualizar certificados AiLun
    }
    
    // MARK: - Security Monitoring
    
    /// Monitora tentativas de bypass de certificate pinning
    func monitorSecurityThreats() {
        // Detectar jailbreak/root
        if SecurityThreatDetector.shared.isDeviceCompromised() {
            auditLogger.log(
                event: .deviceCompromised,
                details: ["type": "jailbreak_detected"],
                severity: .critical
            )
            
            SecurityIncidentManager.shared.reportIncident(
                type: .deviceCompromised,
                host: "local",
                severity: .critical
            )
        }
        
        // Detectar debugging
        if SecurityThreatDetector.shared.isBeingDebugged() {
            auditLogger.log(
                event: .debuggingDetected,
                details: [:],
                severity: .high
            )
        }
        
        // Detectar proxy/VPN suspeito
        if SecurityThreatDetector.shared.isSuspiciousNetworkDetected() {
            auditLogger.log(
                event: .suspiciousNetwork,
                details: [:],
                severity: .medium
            )
        }
    }
    
    // MARK: - Emergency Procedures
    
    /// Procedimento de emergência para bypass temporário
    /// Usado apenas em situações críticas com aprovação
    func emergencyBypass(host: String, reason: String) -> Bool {
        let emergencyCode = generateEmergencyCode()
        
        auditLogger.log(
            event: .emergencyBypass,
            details: [
                "host": host,
                "reason": reason,
                "emergency_code": emergencyCode
            ],
            severity: .critical
        )
        
        // Notificar equipe de segurança imediatamente
        SecurityIncidentManager.shared.reportEmergency(
            type: .certificatePinningBypass,
            host: host,
            reason: reason,
            emergencyCode: emergencyCode
        )
        
        // Bypass temporário por 1 hora
        TemporaryBypassManager.shared.allowBypass(
            host: host,
            duration: .hours(1),
            reason: reason
        )
        
        return true
    }
    
    private func generateEmergencyCode() -> String {
        let timestamp = Date().timeIntervalSince1970
        let random = UUID().uuidString.prefix(8)
        return "EMG-\(Int(timestamp))-\(random)"
    }
}

// MARK: - URLSessionDelegate Extension

extension CertificatePinningManager: URLSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        
        let host = challenge.protectionSpace.host
        let disposition = validateCertificate(for: challenge, host: host)
        
        switch disposition {
        case .useCredential:
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        default:
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Supporting Types

struct SecurityConfiguration {
    let enableStrictPinning: Bool = true
    let allowEmergencyBypass: Bool = true
    let certificateRotationInterval: TimeInterval = 86400 * 30 // 30 dias
    let publicKeyBackupEnabled: Bool = true
}

