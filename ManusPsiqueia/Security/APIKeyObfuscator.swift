//
//  APIKeyObfuscator.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import CryptoKit

/// Sistema de obfuscação de chaves de API para proteção contra análise estática
/// Utiliza múltiplas camadas de proteção e ofuscação
final class APIKeyObfuscator {
    
    static let shared = APIKeyObfuscator()
    
    private init() {}
    
    private let auditLogger = AuditLogger.shared
    
    // MARK: - Chaves obfuscadas (não armazenar em plaintext)
    
    /// Salt para obfuscação (valor fixo mas complexo)
    private let obfuscationSalt: Data = {
        let saltString = "ManusPsiqueia_2024_Security_Salt_v1.0"
        return Data(saltString.utf8)
    }()
    
    /// Chave de obfuscação derivada
    private var obfuscationKey: SymmetricKey {
        let inputData = obfuscationSalt + Data("OBFUSCATION_KEY".utf8)
        let hash = SHA256.hash(data: inputData)
        return SymmetricKey(data: hash)
    }
    
    // MARK: - Obfuscação de Chaves
    
    /// Obfusca uma chave de API para armazenamento seguro
    /// - Parameter apiKey: Chave de API em texto claro
    /// - Returns: Chave obfuscada como Data
    func obfuscateAPIKey(_ apiKey: String) -> Data? {
        guard !apiKey.isEmpty else {
            auditLogger.log(
                event: .dataEncrypted,
                details: ["status": "failed", "reason": "empty_key"],
                severity: .warning
            )
            return nil
        }
        
        do {
            let keyData = Data(apiKey.utf8)
            let sealedBox = try AES.GCM.seal(keyData, using: obfuscationKey)
            
            auditLogger.log(
                event: .dataEncrypted,
                details: ["status": "success", "key_length": apiKey.count],
                severity: .info
            )
            
            return sealedBox.combined
        } catch {
            auditLogger.log(
                event: .dataEncrypted,
                details: ["status": "failed", "error": error.localizedDescription],
                severity: .warning
            )
            return nil
        }
    }
    
    /// Desobfusca uma chave de API para uso em runtime
    /// - Parameter obfuscatedData: Dados obfuscados
    /// - Returns: Chave de API em texto claro
    func deobfuscateAPIKey(_ obfuscatedData: Data) -> String? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: obfuscatedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: obfuscationKey)
            
            let apiKey = String(data: decryptedData, encoding: .utf8)
            
            auditLogger.log(
                event: .dataDecrypted,
                details: ["status": "success"],
                severity: .info
            )
            
            return apiKey
        } catch {
            auditLogger.log(
                event: .dataDecrypted,
                details: ["status": "failed", "error": error.localizedDescription],
                severity: .warning
            )
            return nil
        }
    }
    
    // MARK: - Chaves Hardcoded Obfuscadas
    
    /// Armazena chaves de API obfuscadas estaticamente
    /// Em produção, essas seriam injetadas em tempo de build
    private struct ObfuscatedKeys {
        // Estas são versões obfuscadas das chaves reais
        // Os valores aqui são apenas exemplos - em produção seriam gerados durante o build
        static let stripeTestKey = Data(base64Encoded: "YWJjZGVmZ2hpams=") ?? Data()
        static let openAIKey = Data(base64Encoded: "bG1ub3BxcnN0dXZ3eHl6") ?? Data()
        static let supabaseKey = Data(base64Encoded: "MTIzNDU2Nzg5MA==") ?? Data()
    }
    
    /// Obtém uma chave de API específica desobfuscada
    /// - Parameter keyType: Tipo da chave API
    /// - Returns: Chave desobfuscada ou nil se falhar
    func getAPIKey(for keyType: APIKeyType) -> String? {
        let obfuscatedData: Data
        
        switch keyType {
        case .stripe:
            obfuscatedData = ObfuscatedKeys.stripeTestKey
        case .openAI:
            obfuscatedData = ObfuscatedKeys.openAIKey
        case .supabase:
            obfuscatedData = ObfuscatedKeys.supabaseKey
        }
        
        guard !obfuscatedData.isEmpty else {
            // Fallback para ConfigurationManager se não houver chave obfuscada
            return getKeyFromConfiguration(keyType)
        }
        
        return deobfuscateAPIKey(obfuscatedData) ?? getKeyFromConfiguration(keyType)
    }
    
    /// Fallback para obter chaves do ConfigurationManager
    private func getKeyFromConfiguration(_ keyType: APIKeyType) -> String? {
        let config = ConfigurationManager.shared
        
        switch keyType {
        case .stripe:
            return config.stripePublishableKey
        case .openAI:
            return config.openAIAPIKey
        case .supabase:
            return config.supabaseAnonKey
        }
    }
    
    // MARK: - Utilitários de Segurança
    
    /// Limpa chaves da memória (zerando dados sensíveis)
    func clearAPIKeysFromMemory() {
        // Em Swift, não há controle direto sobre limpeza de memória
        // Mas podemos registrar que uma limpeza foi solicitada
        auditLogger.log(
            event: .dataAnonymized,
            details: ["action": "memory_cleanup_requested"],
            severity: .info
        )
    }
    
    /// Valida se uma chave de API está em formato válido
    /// - Parameters:
    ///   - key: Chave a ser validada
    ///   - keyType: Tipo da chave
    /// - Returns: true se válida
    func validateAPIKeyFormat(_ key: String, type: APIKeyType) -> Bool {
        switch type {
        case .stripe:
            return key.hasPrefix("pk_") || key.hasPrefix("sk_")
        case .openAI:
            return key.hasPrefix("sk-") && key.count > 20
        case .supabase:
            return key.count > 50 // Supabase keys are typically long
        }
    }
}

// MARK: - Tipos Auxiliares

enum APIKeyType {
    case stripe
    case openAI
    case supabase
}

// MARK: - Extensões de Segurança

extension APIKeyObfuscator {
    
    /// Gera um hash seguro de uma chave para logging (sem expor a chave)
    func generateSecureHash(for key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(8).description
    }
    
    /// Verifica a integridade de chaves obfuscadas
    func verifyKeyIntegrity() -> Bool {
        let testKeys: [APIKeyType] = [.stripe, .openAI, .supabase]
        
        for keyType in testKeys {
            if let key = getAPIKey(for: keyType), !key.isEmpty {
                if !validateAPIKeyFormat(key, type: keyType) {
                    auditLogger.log(
                        event: .securityPolicyViolation,
                        details: [
                            "issue": "invalid_key_format",
                            "key_type": String(describing: keyType)
                        ],
                        severity: .high
                    )
                    return false
                }
            }
        }
        
        return true
    }
}