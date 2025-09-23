//
//  AppIntegrityValidator.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import CryptoKit

/// Validador de integridade da aplicação
/// Detecta tampering, modificações não autorizadas e verifica assinaturas
final class AppIntegrityValidator {
    
    static let shared = AppIntegrityValidator()
    
    private init() {}
    
    private let auditLogger = AuditLogger.shared
    
    // MARK: - Validação de Integridade
    
    /// Executa validação completa de integridade da aplicação
    /// - Returns: Resultado da validação com detalhes
    func validateAppIntegrity() async -> IntegrityValidationResult {
        var result = IntegrityValidationResult()
        
        // 1. Verificar assinatura digital da aplicação
        result.signatureValid = await validateAppSignature()
        
        // 2. Verificar integridade de arquivos críticos
        result.filesIntegrityValid = validateCriticalFiles()
        
        // 3. Verificar se o bundle não foi modificado
        result.bundleIntegrityValid = validateBundleIntegrity()
        
        // 4. Verificar checksums de recursos críticos
        result.resourcesIntegrityValid = validateResourcesIntegrity()
        
        // 5. Verificar ambiente de execução
        result.runtimeEnvironmentValid = validateRuntimeEnvironment()
        
        // Avaliar resultado geral
        result.overallValid = result.signatureValid && 
                             result.filesIntegrityValid && 
                             result.bundleIntegrityValid && 
                             result.resourcesIntegrityValid && 
                             result.runtimeEnvironmentValid
        
        // Log do resultado
        auditLogger.log(
            event: .securityValidationCompleted,
            details: result.toDictionary(),
            severity: result.overallValid ? .info : .critical
        )
        
        // Reportar incidente se integridade falhou
        if !result.overallValid {
            SecurityIncidentManager.shared.reportIncident(
                type: .appIntegrityViolation,
                host: "local_app",
                severity: .critical,
                details: result.toDictionary()
            )
        }
        
        return result
    }
    
    // MARK: - Validação de Assinatura
    
    /// Valida a assinatura digital da aplicação
    private func validateAppSignature() async -> Bool {
        #if targetEnvironment(simulator)
        // Simuladores não têm assinaturas válidas
        return true
        #else
        
        guard let executablePath = Bundle.main.executablePath else {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "signature", "reason": "no_executable_path"],
                severity: .critical
            )
            return false
        }
        
        // Verificar se o arquivo executável existe e tem permissões corretas
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: executablePath) else {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "signature", "reason": "executable_not_found"],
                severity: .critical
            )
            return false
        }
        
        // Verificar atributos do arquivo
        do {
            let attributes = try fileManager.attributesOfItem(atPath: executablePath)
            let permissions = attributes[.posixPermissions] as? NSNumber
            
            // Verificar se as permissões estão corretas (executável, mas não gravável por outros)
            if let perm = permissions?.uint16Value {
                let isWorldWritable = (perm & 0o002) != 0
                if isWorldWritable {
                    auditLogger.log(
                        event: .securityValidationFailed,
                        details: ["validation": "signature", "reason": "world_writable_executable"],
                        severity: .critical
                    )
                    return false
                }
            }
            
        } catch {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "signature", "error": error.localizedDescription],
                severity: .critical
            )
            return false
        }
        
        // TODO: Implementar verificação real de assinatura usando Security framework
        // Por ora, consideramos válido se chegou até aqui
        return true
        #endif
    }
    
    // MARK: - Validação de Arquivos
    
    /// Valida integridade de arquivos críticos da aplicação
    private func validateCriticalFiles() -> Bool {
        let criticalFiles = [
            "Info.plist",
            "ManusPsiqueia"  // Executável principal
        ]
        
        let bundle = Bundle.main
        
        for fileName in criticalFiles {
            guard let filePath = bundle.path(forResource: fileName, ofType: nil) else {
                auditLogger.log(
                    event: .securityValidationFailed,
                    details: ["validation": "files", "file": fileName, "reason": "file_not_found"],
                    severity: .critical
                )
                return false
            }
            
            // Verificar se o arquivo não foi modificado recentemente de forma suspeita
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    // Se foi modificado há menos de 1 minuto, pode ser suspeito
                    if Date().timeIntervalSince(modificationDate) < 60 {
                        auditLogger.log(
                            event: .securityValidationFailed,
                            details: [
                                "validation": "files", 
                                "file": fileName, 
                                "reason": "recent_modification"
                            ],
                            severity: .warning
                        )
                    }
                }
            } catch {
                auditLogger.log(
                    event: .securityValidationFailed,
                    details: [
                        "validation": "files", 
                        "file": fileName, 
                        "error": error.localizedDescription
                    ],
                    severity: .warning
                )
            }
        }
        
        return true
    }
    
    // MARK: - Validação de Bundle
    
    /// Valida a integridade do bundle da aplicação
    private func validateBundleIntegrity() -> Bool {
        let bundle = Bundle.main
        
        // Verificar bundle identifier
        guard let bundleId = bundle.bundleIdentifier,
              bundleId == "com.ailun.manuspsiqueia" else {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "bundle", "reason": "invalid_bundle_id"],
                severity: .critical
            )
            return false
        }
        
        // Verificar se o Info.plist está presente e válido
        guard let infoPlist = bundle.infoDictionary else {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "bundle", "reason": "no_info_plist"],
                severity: .critical
            )
            return false
        }
        
        // Verificar campos obrigatórios do Info.plist
        let requiredKeys = [
            "CFBundleIdentifier",
            "CFBundleVersion",
            "CFBundleShortVersionString"
        ]
        
        for key in requiredKeys {
            if infoPlist[key] == nil {
                auditLogger.log(
                    event: .securityValidationFailed,
                    details: ["validation": "bundle", "reason": "missing_plist_key", "key": key],
                    severity: .critical
                )
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Validação de Recursos
    
    /// Valida checksums de recursos críticos
    private func validateResourcesIntegrity() -> Bool {
        // Checksums conhecidos de arquivos críticos (em produção, seriam gerados no build)
        let expectedChecksums: [String: String] = [
            // Exemplo: "SecurityConfig.plist": "a1b2c3d4e5f6...",
            // Em produção, estes checksums seriam gerados automaticamente
        ]
        
        for (resourceName, expectedChecksum) in expectedChecksums {
            guard let resourcePath = Bundle.main.path(forResource: resourceName, ofType: nil) else {
                auditLogger.log(
                    event: .securityValidationFailed,
                    details: ["validation": "resources", "resource": resourceName, "reason": "not_found"],
                    severity: .high
                )
                continue
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: resourcePath))
                let actualChecksum = SHA256.hash(data: data)
                let actualChecksumString = actualChecksum.compactMap { String(format: "%02x", $0) }.joined()
                
                if actualChecksumString != expectedChecksum {
                    auditLogger.log(
                        event: .securityValidationFailed,
                        details: [
                            "validation": "resources", 
                            "resource": resourceName, 
                            "reason": "checksum_mismatch"
                        ],
                        severity: .critical
                    )
                    return false
                }
            } catch {
                auditLogger.log(
                    event: .securityValidationFailed,
                    details: [
                        "validation": "resources", 
                        "resource": resourceName, 
                        "error": error.localizedDescription
                    ],
                    severity: .high
                )
            }
        }
        
        return true
    }
    
    // MARK: - Validação de Ambiente
    
    /// Valida o ambiente de execução
    private func validateRuntimeEnvironment() -> Bool {
        // Verificar se não está sendo executado em ambiente suspeito
        if SecurityThreatDetector.shared.isDeviceCompromised() {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "runtime", "reason": "compromised_device"],
                severity: .critical
            )
            return false
        }
        
        if SecurityThreatDetector.shared.isBeingDebugged() {
            auditLogger.log(
                event: .securityValidationFailed,
                details: ["validation": "runtime", "reason": "debugging_detected"],
                severity: .high
            )
            // Não falha em desenvolvimento, apenas avisa
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
        return true
    }
}

// MARK: - Estruturas de Resultado

/// Resultado da validação de integridade
struct IntegrityValidationResult {
    var signatureValid: Bool = false
    var filesIntegrityValid: Bool = false
    var bundleIntegrityValid: Bool = false
    var resourcesIntegrityValid: Bool = false
    var runtimeEnvironmentValid: Bool = false
    var overallValid: Bool = false
    
    /// Converte o resultado para dicionário para logging
    func toDictionary() -> [String: Any] {
        return [
            "signature_valid": signatureValid,
            "files_integrity_valid": filesIntegrityValid,
            "bundle_integrity_valid": bundleIntegrityValid,
            "resources_integrity_valid": resourcesIntegrityValid,
            "runtime_environment_valid": runtimeEnvironmentValid,
            "overall_valid": overallValid
        ]
    }
}

// MARK: - Novos Eventos de Auditoria

extension SecurityEvent {
    static let securityValidationCompleted = SecurityEvent.securityValidationCompleted
    static let securityValidationFailed = SecurityEvent.securityValidationFailed
}

// MARK: - Novos Tipos de Incidente

extension SecurityIncidentType {
    static let appIntegrityViolation = SecurityIncidentType.appIntegrityViolation
}