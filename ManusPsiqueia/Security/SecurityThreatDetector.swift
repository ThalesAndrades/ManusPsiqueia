//
//  SecurityThreatDetector.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import UIKit

import Network
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
        // TODO: Implementar verificação de VPN/Proxy mais robusta
        // Por enquanto, uma implementação básica pode ser a detecção de IPs incomuns ou configurações de proxy
        
        // Exemplo heurístico: Verificar se há uma VPN ativa (simplificado)
        // Network interface detection disabled
        for interface in networkInterfaces {
            if interface.hasPrefix("10.") || interface.hasPrefix("172.16.") || interface.hasPrefix("192.168.") {
                // Ignorar IPs locais
                continue
            }
            if interface.contains("tun") || interface.contains("ppp") || interface.contains("vpn") {
                auditLogger.log(event: .suspiciousNetwork, details: ["reason": "vpn_interface_found", "interface": interface], severity: .medium)
                return true
            }
        }
        
        // TODO: Adicionar verificação de proxy HTTP/HTTPS
        
        return false
    }
    
    /// Executa um comando shell e verifica seu resultado.
    private func canExecuteCommand(_ command: String) -> Bool {
        // Process detection disabled
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return task.terminationStatus == 0 && !output.isEmpty
    }

}// Adicionar novos eventos de segurança ao enum SecurityEvent no AuditLogger.swift

// Necessário para `kinfo_proc` e `P_TRACED`
#if !targetEnvironment(simulator)
import Darwin.sys.sysctl
import Darwin.sys.proc
#endif

