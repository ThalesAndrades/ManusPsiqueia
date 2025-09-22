//
//  ConfigurationManager.swift
//  ManusPsiqueia
//
//  Gerenciador de configurações para diferentes ambientes
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 ManusPsiqueia. All rights reserved.
//

import Foundation

// MARK: - Configuration Manager

final class ConfigurationManager {
    
    // MARK: - Singleton
    
    static let shared = ConfigurationManager()
    
    private init() {}
    
    // MARK: - Environment Detection
    
    enum Environment: String, CaseIterable {
        case development = "DEVELOPMENT"
        case staging = "STAGING"
        case production = "PRODUCTION"
        
        var displayName: String {
            switch self {
            case .development:
                return "Desenvolvimento"
            case .staging:
                return "Staging"
            case .production:
                return "Produção"
            }
        }
    }
    
    var currentEnvironment: Environment {
        #if DEVELOPMENT
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    // MARK: - App Configuration
    
    var appDisplayName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "ManusPsiqueia"
    }
    
    var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.ailun.manuspsiqueia"
    }
    
    var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    // MARK: - API Configuration
    
    var apiBaseURL: String {
        switch currentEnvironment {
        case .development:
            return "https://api-dev.manuspsiqueia.com"
        case .staging:
            return "https://api-staging.manuspsiqueia.com"
        case .production:
            return "https://api.manuspsiqueia.com"
        }
    }
    
    var apiVersion: String {
        return "v1"
    }
    
    var fullAPIURL: String {
        return "\(apiBaseURL)/\(apiVersion)"
    }
    
    // MARK: - Stripe Configuration
    
    var stripePublishableKey: String {
        switch currentEnvironment {
        case .development:
            return "pk_test_development_key_here"
        case .staging:
            return getSecretValue(for: "STRIPE_PUBLISHABLE_KEY_STAGING") ?? ""
        case .production:
            return getSecretValue(for: "STRIPE_PUBLISHABLE_KEY_PROD") ?? ""
        }
    }
    
    var stripeWebhookEndpoint: String {
        return "\(apiBaseURL)/webhooks/stripe"
    }
    
    // MARK: - Supabase Configuration
    
    var supabaseURL: String {
        switch currentEnvironment {
        case .development:
            return "https://dev-project.supabase.co"
        case .staging:
            return getSecretValue(for: "SUPABASE_URL_STAGING") ?? ""
        case .production:
            return getSecretValue(for: "SUPABASE_URL_PROD") ?? ""
        }
    }
    
    var supabaseAnonKey: String {
        switch currentEnvironment {
        case .development:
            return "development_anon_key_here"
        case .staging:
            return getSecretValue(for: "SUPABASE_ANON_KEY_STAGING") ?? ""
        case .production:
            return getSecretValue(for: "SUPABASE_ANON_KEY_PROD") ?? ""
        }
    }
    
    // MARK: - OpenAI Configuration
    
    var openAIAPIEndpoint: String {
        return "https://api.openai.com/v1"
    }
    
    var openAIModel: String {
        return "gpt-4"
    }
    
    var openAIAPIKey: String {
        return getSecretValue(for: "OPENAI_API_KEY") ?? ""
    }
    
    // MARK: - Feature Flags
    
    var isDebugMenuEnabled: Bool {
        switch currentEnvironment {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
    
    var isAnalyticsEnabled: Bool {
        switch currentEnvironment {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }
    
    var isCrashReportingEnabled: Bool {
        switch currentEnvironment {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }
    
    var isLoggingEnabled: Bool {
        switch currentEnvironment {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
    
    // MARK: - Security Configuration
    
    var isCertificatePinningEnabled: Bool {
        switch currentEnvironment {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }
    
    enum NetworkSecurityLevel: String {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
    }
    
    var networkSecurityLevel: NetworkSecurityLevel {
        switch currentEnvironment {
        case .development:
            return .low
        case .staging:
            return .medium
        case .production:
            return .high
        }
    }
    
    // MARK: - Private Methods
    
    private func getSecretValue(for key: String) -> String? {
        // Primeiro, tenta buscar nas variáveis de ambiente
        if let envValue = ProcessInfo.processInfo.environment[key] {
            return envValue
        }
        
        // Depois, tenta buscar no Info.plist
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return plistValue
        }
        
        // Por último, tenta buscar no Keychain (para valores sensíveis)
        return getKeychainValue(for: key)
    }
    
    private func getKeychainValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Keychain Management
    
    func storeSecretInKeychain(key: String, value: String) -> Bool {
        // Remove valor existente
        deleteSecretFromKeychain(key: key)
        
        // Adiciona novo valor
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func deleteSecretFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Configuration Validation
    
    func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        // Validar configurações críticas
        if stripePublishableKey.isEmpty {
            errors.append("Stripe Publishable Key não configurada")
        }
        
        if supabaseURL.isEmpty {
            errors.append("Supabase URL não configurada")
        }
        
        if supabaseAnonKey.isEmpty {
            errors.append("Supabase Anon Key não configurada")
        }
        
        if openAIAPIKey.isEmpty {
            errors.append("OpenAI API Key não configurada")
        }
        
        // Validar URLs
        if URL(string: apiBaseURL) == nil {
            errors.append("API Base URL inválida")
        }
        
        if URL(string: supabaseURL) == nil {
            errors.append("Supabase URL inválida")
        }
        
        return errors
    }
    
    // MARK: - Debug Information
    
    func getDebugInfo() -> [String: Any] {
        return [
            "environment": currentEnvironment.displayName,
            "app_version": appVersion,
            "build_number": buildNumber,
            "bundle_identifier": bundleIdentifier,
            "api_base_url": apiBaseURL,
            "debug_menu_enabled": isDebugMenuEnabled,
            "analytics_enabled": isAnalyticsEnabled,
            "crash_reporting_enabled": isCrashReportingEnabled,
            "logging_enabled": isLoggingEnabled,
            "certificate_pinning_enabled": isCertificatePinningEnabled,
            "network_security_level": networkSecurityLevel.rawValue
        ]
    }
}

// MARK: - Configuration Extensions

extension ConfigurationManager {
    
    /// Retorna a configuração completa para logging
    var loggingConfiguration: [String: Any] {
        return [
            "enabled": isLoggingEnabled,
            "level": currentEnvironment == .production ? "ERROR" : "DEBUG",
            "remote_logging": currentEnvironment != .development
        ]
    }
    
    /// Retorna a configuração de timeout para requests
    var networkTimeoutConfiguration: (connect: TimeInterval, request: TimeInterval) {
        switch networkSecurityLevel {
        case .low:
            return (connect: 10.0, request: 30.0)
        case .medium:
            return (connect: 8.0, request: 20.0)
        case .high:
            return (connect: 5.0, request: 15.0)
        }
    }
}
