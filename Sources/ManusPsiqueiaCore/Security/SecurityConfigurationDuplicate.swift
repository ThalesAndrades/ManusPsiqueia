//
//  SecurityConfiguration.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation

/// Configurações globais de segurança para o aplicativo ManusPsiqueia
/// Permite gerenciar o comportamento de recursos de segurança como Certificate Pinning
public struct SecurityConfiguration {
    
    /// Habilita o Certificate Pinning estrito para todas as conexões críticas
    let enableStrictPinning: Bool = true
    
    /// Permite o bypass de emergência do Certificate Pinning em situações críticas
    /// Deve ser usado com extrema cautela e apenas com aprovação de segurança
    let allowEmergencyBypass: Bool = false // Default para false em produção
    
    /// Intervalo de rotação de certificados em segundos (e.g., 30 dias)
    let certificateRotationInterval: TimeInterval = 86400 * 30
    
    /// Habilita o backup de chaves públicas para Certificate Pinning
    let publicKeyBackupEnabled: Bool = true
    
    /// Lista de hosts para os quais o Certificate Pinning é obrigatório
    let pinnedHosts: [String] = [
        "api.stripe.com",
        "api.supabase.co",
        "api.openai.com",
        "api.ailun.com.br"
    ]
    
    /// Habilita a detecção de jailbreak/root
    let enableJailbreakDetection: Bool = true
    
    /// Habilita a detecção de depuração (debugging)
    let enableDebuggingDetection: Bool = true
    
    /// Habilita a detecção de redes suspeitas (proxy/VPN)
    let enableSuspiciousNetworkDetection: Bool = true
    
    /// Habilita o log de auditoria detalhado
    let enableDetailedAuditLogging: Bool = true
    
    /// Política de retenção de logs de auditoria em dias
    let auditLogRetentionDays: Int = 365 * 7 // 7 anos
    
    /// Nível mínimo de severidade para alertas de segurança
    let minimumAlertSeverity: SecuritySeverity = .high
    
    /// URL do servidor de relatórios de incidentes de segurança
    let incidentReportURL: URL? = URL(string: "https://security.ailun.com.br/incidents")
    
    /// Chave pública para criptografia de dados sensíveis (e.g., para comunicação com backend)
    let encryptionPublicKey: String = "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
    
    /// Habilita o monitoramento de integridade do aplicativo (tampering detection)
    let enableAppIntegrityMonitoring: Bool = true
    
    /// Habilita o uso de Secure Enclave para armazenamento de chaves críticas
    let enableSecureEnclave: Bool = true
}
