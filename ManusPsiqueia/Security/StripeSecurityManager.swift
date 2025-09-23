//
//  StripeSecurityManager.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftKeychainWrapper
import CryptoKit

// MARK: - Stripe Security Manager
@MainActor
class StripeSecurityManager: ObservableObject {
    static let shared = StripeSecurityManager()
    
    @Published var isConfigured = false
    @Published var errorMessage: String?
    
    private let auditLogger = AuditLogger.shared
    private let keychainService = "ManusPsiqueia.Stripe.SecretKeys"
    
    // MARK: - Key Identifiers
    private enum KeyIdentifier: String, CaseIterable {
        case publishableKeyDev = "stripe_publishable_key_dev"
        case secretKeyDev = "stripe_secret_key_dev"
        case webhookSecretDev = "stripe_webhook_secret_dev"
        
        case publishableKeyStaging = "stripe_publishable_key_staging"
        case secretKeyStaging = "stripe_secret_key_staging"
        case webhookSecretStaging = "stripe_webhook_secret_staging"
        
        case publishableKeyProd = "stripe_publishable_key_prod"
        case secretKeyProd = "stripe_secret_key_prod"
        case webhookSecretProd = "stripe_webhook_secret_prod"
        
        var environment: BuildEnvironment {
            switch self {
            case .publishableKeyDev, .secretKeyDev, .webhookSecretDev:
                return .development
            case .publishableKeyStaging, .secretKeyStaging, .webhookSecretStaging:
                return .staging
            case .publishableKeyProd, .secretKeyProd, .webhookSecretProd:
                return .production
            }
        }
        
        var keyType: StripeKeyType {
            switch self {
            case .publishableKeyDev, .publishableKeyStaging, .publishableKeyProd:
                return .publishable
            case .secretKeyDev, .secretKeyStaging, .secretKeyProd:
                return .secret
            case .webhookSecretDev, .webhookSecretStaging, .webhookSecretProd:
                return .webhook
            }
        }
    }
    
    // MARK: - Environment Detection
    private var currentEnvironment: BuildEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    init() {
        validateConfiguration()
    }
    
    // MARK: - Key Management
    
    /// Armazena uma chave do Stripe de forma segura no Keychain
    func storeStripeKey(_ key: String, type: StripeKeyType, environment: BuildEnvironment) throws {
        guard !key.isEmpty else {
            throw StripeSecurityError.emptyKey
        }
        
        guard validateKeyFormat(key, type: type) else {
            throw StripeSecurityError.invalidKeyFormat
        }
        
        let identifier = getKeyIdentifier(type: type, environment: environment)
        let encryptedKey = try encryptKey(key)
        
        let success = KeychainWrapper.standard.set(
            encryptedKey,
            forKey: identifier.rawValue,
            withAccessibility: .whenUnlockedThisDeviceOnly
        )
        
        guard success else {
            throw StripeSecurityError.keychainStorageError
        }
        
        auditLogger.log(
            event: .securityEvent,
            severity: .info,
            details: "Chave Stripe armazenada: \(type.rawValue) - \(environment.rawValue)"
        )
        
        validateConfiguration()
    }
    
    /// Recupera uma chave do Stripe do Keychain
    func getStripeKey(type: StripeKeyType, environment: BuildEnvironment? = nil) throws -> String {
        let env = environment ?? currentEnvironment
        let identifier = getKeyIdentifier(type: type, environment: env)
        
        guard let encryptedKey = KeychainWrapper.standard.string(forKey: identifier.rawValue) else {
            // Fallback para variáveis de ambiente em desenvolvimento
            if env == .development, let envKey = getEnvironmentKey(type: type, environment: env) {
                return envKey
            }
            throw StripeSecurityError.keyNotFound
        }
        
        let decryptedKey = try decryptKey(encryptedKey)
        
        auditLogger.log(
            event: .securityEvent,
            severity: .info,
            details: "Chave Stripe acessada: \(type.rawValue) - \(env.rawValue)"
        )
        
        return decryptedKey
    }
    
    /// Remove uma chave específica do Keychain
    func removeStripeKey(type: StripeKeyType, environment: BuildEnvironment) {
        let identifier = getKeyIdentifier(type: type, environment: environment)
        KeychainWrapper.standard.removeObject(forKey: identifier.rawValue)
        
        auditLogger.log(
            event: .securityEvent,
            severity: .warning,
            details: "Chave Stripe removida: \(type.rawValue) - \(environment.rawValue)"
        )
        
        validateConfiguration()
    }
    
    /// Remove todas as chaves do Stripe do Keychain
    func clearAllStripeKeys() {
        for identifier in KeyIdentifier.allCases {
            KeychainWrapper.standard.removeObject(forKey: identifier.rawValue)
        }
        
        auditLogger.log(
            event: .securityEvent,
            severity: .critical,
            details: "Todas as chaves Stripe foram removidas"
        )
        
        isConfigured = false
    }
    
    // MARK: - Configuration Validation
    
    private func validateConfiguration() {
        let requiredKeys: [StripeKeyType] = [.publishable, .secret, .webhook]
        
        var hasAllKeys = true
        for keyType in requiredKeys {
            do {
                _ = try getStripeKey(type: keyType)
            } catch {
                hasAllKeys = false
                break
            }
        }
        
        isConfigured = hasAllKeys
        
        if !isConfigured {
            auditLogger.log(
                event: .securityEvent,
                severity: .warning,
                details: "Configuração do Stripe incompleta para ambiente: \(currentEnvironment.rawValue)"
            )
        }
    }
    
    // MARK: - Key Validation
    
    private func validateKeyFormat(_ key: String, type: StripeKeyType) -> Bool {
        switch type {
        case .publishable:
            return key.hasPrefix("pk_test_") || key.hasPrefix("pk_live_")
        case .secret:
            return key.hasPrefix("sk_test_") || key.hasPrefix("sk_live_")
        case .webhook:
            return key.hasPrefix("whsec_")
        }
    }
    
    // MARK: - Encryption/Decryption
    
    private func encryptKey(_ key: String) throws -> String {
        guard let keyData = key.data(using: .utf8) else {
            throw StripeSecurityError.encryptionError
        }
        
        let deviceKey = getDeviceSpecificKey()
        let sealedBox = try AES.GCM.seal(keyData, using: deviceKey)
        
        guard let encryptedData = sealedBox.combined else {
            throw StripeSecurityError.encryptionError
        }
        
        return encryptedData.base64EncodedString()
    }
    
    private func decryptKey(_ encryptedKey: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedKey) else {
            throw StripeSecurityError.decryptionError
        }
        
        let deviceKey = getDeviceSpecificKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: deviceKey)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw StripeSecurityError.decryptionError
        }
        
        return decryptedString
    }
    
    private func getDeviceSpecificKey() -> SymmetricKey {
        // Usar identificador único do dispositivo para criar chave de criptografia
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "default-device-id"
        let keyData = SHA256.hash(data: Data(deviceId.utf8))
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Helper Methods
    
    private func getKeyIdentifier(type: StripeKeyType, environment: BuildEnvironment) -> KeyIdentifier {
        switch (type, environment) {
        case (.publishable, .development):
            return .publishableKeyDev
        case (.secret, .development):
            return .secretKeyDev
        case (.webhook, .development):
            return .webhookSecretDev
        case (.publishable, .staging):
            return .publishableKeyStaging
        case (.secret, .staging):
            return .secretKeyStaging
        case (.webhook, .staging):
            return .webhookSecretStaging
        case (.publishable, .production):
            return .publishableKeyProd
        case (.secret, .production):
            return .secretKeyProd
        case (.webhook, .production):
            return .webhookSecretProd
        }
    }
    
    private func getEnvironmentKey(type: StripeKeyType, environment: BuildEnvironment) -> String? {
        let envVar: String
        
        switch (type, environment) {
        case (.publishable, .development):
            envVar = "STRIPE_PUBLISHABLE_KEY_DEV"
        case (.secret, .development):
            envVar = "STRIPE_SECRET_KEY_DEV"
        case (.webhook, .development):
            envVar = "STRIPE_WEBHOOK_SECRET_DEV"
        case (.publishable, .staging):
            envVar = "STRIPE_PUBLISHABLE_KEY_STAGING"
        case (.secret, .staging):
            envVar = "STRIPE_SECRET_KEY_STAGING"
        case (.webhook, .staging):
            envVar = "STRIPE_WEBHOOK_SECRET_STAGING"
        case (.publishable, .production):
            envVar = "STRIPE_PUBLISHABLE_KEY_PROD"
        case (.secret, .production):
            envVar = "STRIPE_SECRET_KEY_PROD"
        case (.webhook, .production):
            envVar = "STRIPE_WEBHOOK_SECRET_PROD"
        }
        
        return ProcessInfo.processInfo.environment[envVar]
    }
    
    // MARK: - Security Audit
    
    /// Realiza auditoria de segurança das chaves
    func performSecurityAudit() -> StripeSecurityAudit {
        var audit = StripeSecurityAudit()
        
        // Verificar se todas as chaves estão presentes
        for environment in BuildEnvironment.allCases {
            for keyType in StripeKeyType.allCases {
                do {
                    let key = try getStripeKey(type: keyType, environment: environment)
                    
                    // Verificar formato da chave
                    if validateKeyFormat(key, type: keyType) {
                        audit.validKeys.append((keyType, environment))
                    } else {
                        audit.invalidKeys.append((keyType, environment))
                    }
                    
                    // Verificar se é chave de produção em ambiente de desenvolvimento
                    if environment == .development && (key.contains("live") || key.contains("prod")) {
                        audit.securityWarnings.append("Chave de produção detectada em ambiente de desenvolvimento")
                    }
                    
                } catch {
                    audit.missingKeys.append((keyType, environment))
                }
            }
        }
        
        audit.auditDate = Date()
        audit.isSecure = audit.invalidKeys.isEmpty && audit.securityWarnings.isEmpty
        
        auditLogger.log(
            event: .securityEvent,
            severity: audit.isSecure ? .info : .warning,
            details: "Auditoria de segurança realizada - Seguro: \(audit.isSecure)"
        )
        
        return audit
    }
}

// MARK: - Supporting Types

enum StripeKeyType: String, CaseIterable {
    case publishable = "publishable"
    case secret = "secret"
    case webhook = "webhook"
    
    var displayName: String {
        switch self {
        case .publishable:
            return "Chave Publicável"
        case .secret:
            return "Chave Secreta"
        case .webhook:
            return "Segredo do Webhook"
        }
    }
}

enum BuildEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var displayName: String {
        switch self {
        case .development:
            return "Desenvolvimento"
        case .staging:
            return "Homologação"
        case .production:
            return "Produção"
        }
    }
}

struct StripeSecurityAudit {
    var validKeys: [(StripeKeyType, BuildEnvironment)] = []
    var invalidKeys: [(StripeKeyType, BuildEnvironment)] = []
    var missingKeys: [(StripeKeyType, BuildEnvironment)] = []
    var securityWarnings: [String] = []
    var auditDate: Date = Date()
    var isSecure: Bool = false
}

// MARK: - Errors

enum StripeSecurityError: LocalizedError {
    case emptyKey
    case invalidKeyFormat
    case keyNotFound
    case keychainStorageError
    case encryptionError
    case decryptionError
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Chave não pode estar vazia"
        case .invalidKeyFormat:
            return "Formato da chave inválido"
        case .keyNotFound:
            return "Chave não encontrada"
        case .keychainStorageError:
            return "Erro ao armazenar no Keychain"
        case .encryptionError:
            return "Erro na criptografia"
        case .decryptionError:
            return "Erro na descriptografia"
        case .configurationError:
            return "Erro de configuração"
        }
    }
}
