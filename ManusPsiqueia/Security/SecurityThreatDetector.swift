//
//  SecurityThreatDetector.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Network

#if !targetEnvironment(simulator)
import Darwin.sys.sysctl
import Darwin.sys.proc
#endif

// Importar para verificação de interfaces de rede
#if canImport(Darwin)
import Darwin
#endif
/// Detecta ameaças de segurança no dispositivo, como jailbreak, depuração e redes suspeitas.
/// Utilizado pelo CertificatePinningManager para monitoramento proativo.
final class SecurityThreatDetector {
    
    static let shared = SecurityThreatDetector()
    
    private init() {}
    
    private let auditLogger = AuditLogger.shared
    
    /// Verifica se o dispositivo está comprometido (jailbreak/root).
    /// - Returns: `true` se o dispositivo estiver jailbroken/rooted, `false` caso contrário.
    func isDeviceCompromised() -> Bool {
        #if targetEnvironment(simulator)
        // Simuladores não podem ser jailbroken, retornar false para testes
        return false
        #else
        // 1. Verificar arquivos e diretórios comuns de jailbreak
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/mobile/Library/Cydia",
            "/private/var/stash",
            "/usr/bin/ssh",
            "/var/log/syslog"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                auditLogger.log(event: .deviceCompromised, details: ["reason": "jailbreak_file_found", "path": path], severity: .critical)
                return true
            }
        }
        
        // 2. Verificar se pode escrever em áreas restritas
        let testPath = "/private/jailbreak.test"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            auditLogger.log(event: .deviceCompromised, details: ["reason": "writable_restricted_area"], severity: .critical)
            return true
        } catch { /* Expected to fail on non-jailbroken devices */ }
        
        // 3. Verificar variáveis de ambiente de jailbreak
        if let env = getenv("DYLD_INSERT_LIBRARIES") {
            let libraries = String(cString: env)
            if libraries.contains("Substrate") || libraries.contains("Cydia") {
                auditLogger.log(event: .deviceCompromised, details: ["reason": "jailbreak_env_var"], severity: .critical)
                return true
            }
        }
        
        // 4. Verificar se o app pode abrir URLs de Cydia
        if UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!) {
            auditLogger.log(event: .deviceCompromised, details: ["reason": "cydia_url_scheme"], severity: .critical)
            return true
        }
        
        // 5. Verificar se o dispositivo tem permissões de root (e.g., via `which ssh`)
        if canExecuteCommand("which ssh") {
            auditLogger.log(event: .deviceCompromised, details: ["reason": "ssh_executable_found"], severity: .critical)
            return true
        }
        
        return false
        #endif
    }
    
    /// Verifica se o aplicativo está sendo depurado.
    /// - Returns: `true` se o aplicativo estiver sendo depurado, `false` caso contrário.
    func isBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout.stride(ofValue: info)
        let sysctlResult = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        guard sysctlResult == 0 else {
            auditLogger.log(event: .debuggingDetected, details: ["reason": "sysctl_failed"], severity: .high)
            return false
        }
        
        let isDebugging = (info.kp_proc.p_flag & P_TRACED) != 0
        if isDebugging {
            auditLogger.log(event: .debuggingDetected, details: ["reason": "ptrace_flag_set"], severity: .high)
        }
        return isDebugging
    }
    
    /// Verifica se há uma rede suspeita (e.g., VPN ou proxy não autorizado).
    /// Esta é uma verificação heurística e pode gerar falsos positivos.
    /// - Returns: `true` se uma rede suspeita for detectada, `false` caso contrário.
    func isSuspiciousNetworkDetected() -> Bool {
        #if targetEnvironment(simulator)
        // Simuladores podem ter configurações de rede diferentes
        return false
        #else
        
        // Verificar configurações de proxy do sistema
        if let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] {
            if let httpProxy = proxySettings["HTTPProxy"] as? String, !httpProxy.isEmpty {
                auditLogger.log(
                    event: .suspiciousNetwork, 
                    details: ["reason": "http_proxy_detected", "proxy": httpProxy], 
                    severity: .medium
                )
                return true
            }
            
            if let httpsProxy = proxySettings["HTTPSProxy"] as? String, !httpsProxy.isEmpty {
                auditLogger.log(
                    event: .suspiciousNetwork, 
                    details: ["reason": "https_proxy_detected", "proxy": httpsProxy], 
                    severity: .medium
                )
                return true
            }
        }
        
        // Verificar interfaces de rede suspeitas
        if hasVPNInterface() {
            auditLogger.log(
                event: .suspiciousNetwork, 
                details: ["reason": "vpn_interface_detected"], 
                severity: .medium
            )
            return true
        }
        
        return false
        #endif
    }
    
    /// Verifica se há interfaces VPN ativas
    private func hasVPNInterface() -> Bool {
        var addresses = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return false }
        guard let firstAddr = ifaddr else { return false }
        
        defer { freeifaddrs(ifaddr) }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                
                // Verificar nomes de interfaces típicas de VPN
                if name.contains("tun") || name.contains("tap") || 
                   name.contains("ppp") || name.contains("ipsec") ||
                   name.hasPrefix("utun") {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Executa um comando shell e verifica seu resultado.
    private func canExecuteCommand(_ command: String) -> Bool {
        // Em iOS, não podemos executar comandos shell arbitrários
        // Esta é uma implementação simulada para compatibilidade
        #if targetEnvironment(simulator)
        return false
        #else
        // Em um ambiente real iOS, esta verificação seria diferente
        // Por exemplo, verificar se o arquivo existe no sistema
        return FileManager.default.fileExists(atPath: "/usr/bin/ssh")
        #endif
    }
    
    /// Realiza uma verificação completa de ameaças de segurança
    /// - Returns: Relatório detalhado das ameaças encontradas
    func performComprehensiveSecurityScan() -> SecurityThreatReport {
        var report = SecurityThreatReport()
        
        report.deviceCompromised = isDeviceCompromised()
        report.debuggingDetected = isBeingDebugged()
        report.suspiciousNetworkDetected = isSuspiciousNetworkDetected()
        report.timestamp = Date()
        
        // Calcular score de risco (0-100, onde 100 é mais perigoso)
        var riskScore = 0
        if report.deviceCompromised { riskScore += 40 }
        if report.debuggingDetected { riskScore += 20 }
        if report.suspiciousNetworkDetected { riskScore += 15 }
        
        report.riskScore = riskScore
        report.riskLevel = SecurityRiskLevel.from(score: riskScore)
        
        // Log do resultado
        auditLogger.log(
            event: .securityValidationCompleted,
            details: report.toDictionary(),
            severity: report.riskLevel.severity
        )
        
        return report
    }

}

// MARK: - Estruturas de Suporte

/// Relatório de ameaças de segurança
struct SecurityThreatReport {
    var deviceCompromised: Bool = false
    var debuggingDetected: Bool = false
    var suspiciousNetworkDetected: Bool = false
    var timestamp: Date = Date()
    var riskScore: Int = 0
    var riskLevel: SecurityRiskLevel = .low
    
    func toDictionary() -> [String: Any] {
        return [
            "device_compromised": deviceCompromised,
            "debugging_detected": debuggingDetected,
            "suspicious_network_detected": suspiciousNetworkDetected,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "risk_score": riskScore,
            "risk_level": riskLevel.rawValue
        ]
    }
}

/// Níveis de risco de segurança
enum SecurityRiskLevel: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    static func from(score: Int) -> SecurityRiskLevel {
        switch score {
        case 0...20:
            return .low
        case 21...40:
            return .medium
        case 41...70:
            return .high
        default:
            return .critical
        }
    }
    
    var severity: SecuritySeverity {
        switch self {
        case .low:
            return .info
        case .medium:
            return .medium
        case .high:
            return .high
        case .critical:
            return .critical
        }
    }
}

// Necessário para `kinfo_proc` e `P_TRACED`
#if !targetEnvironment(simulator)
// Já importado acima
#endif

