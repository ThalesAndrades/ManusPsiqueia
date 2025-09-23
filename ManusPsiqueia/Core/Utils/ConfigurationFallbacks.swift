//
//  ConfigurationFallbacks.swift
//  ManusPsiqueia
//
//  Fallbacks para configurações quando variáveis de ambiente não estão disponíveis
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation

// MARK: - Configuration Fallbacks

struct ConfigurationFallbacks {
    
    // MARK: - Stripe Fallbacks
    
    static let stripePublishableKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "StripePublishableKey") as? String,
           !key.isEmpty && !key.contains("$(") {
            return key
        }
        
        #if DEBUG
        return "pk_test_51234567890abcdef" // Placeholder para desenvolvimento
        #else
        return "pk_live_placeholder" // Placeholder para produção
        #endif
    }()
    
    // MARK: - Supabase Fallbacks
    
    static let supabaseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
           !url.isEmpty && !url.contains("$(") {
            return url
        }
        
        return "https://placeholder.supabase.co"
    }()
    
    static let supabaseAnonKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
           !key.isEmpty && !key.contains("$(") {
            return key
        }
        
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder"
    }()
    
    // MARK: - OpenAI Fallbacks
    
    static let openAIAPIKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String,
           !key.isEmpty && !key.contains("$(") {
            return key
        }
        
        return "sk-placeholder-openai-key"
    }()
    
    // MARK: - Build Environment
    
    static let buildEnvironment: String = {
        if let env = Bundle.main.object(forInfoDictionaryKey: "BuildEnvironment") as? String,
           !env.isEmpty && !env.contains("$(") {
            return env
        }
        
        #if DEBUG
        return "Development"
        #else
        return "Production"
        #endif
    }()
    
    static let isDebugBuild: Bool = {
        if let debug = Bundle.main.object(forInfoDictionaryKey: "IsDebugBuild") as? String,
           !debug.isEmpty && !debug.contains("$(") {
            return debug.lowercased() == "yes" || debug.lowercased() == "true"
        }
        
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Validation Methods
    
    static func isPlaceholder(_ value: String) -> Bool {
        return value.contains("placeholder") || 
               value.contains("$(") || 
               value.isEmpty ||
               value == "YOUR_KEY_HERE"
    }
    
    static func validateConfiguration() -> [String] {
        var warnings: [String] = []
        
        if isPlaceholder(stripePublishableKey) {
            warnings.append("Stripe: Usando chave placeholder")
        }
        
        if isPlaceholder(supabaseURL) {
            warnings.append("Supabase: Usando URL placeholder")
        }
        
        if isPlaceholder(supabaseAnonKey) {
            warnings.append("Supabase: Usando chave anônima placeholder")
        }
        
        if isPlaceholder(openAIAPIKey) {
            warnings.append("OpenAI: Usando chave placeholder")
        }
        
        return warnings
    }
    
    // MARK: - Safe Configuration Access
    
    static func getStripeKey() -> String? {
        let key = stripePublishableKey
        return isPlaceholder(key) ? nil : key
    }
    
    static func getSupabaseConfig() -> (url: String?, anonKey: String?)? {
        let url = supabaseURL
        let key = supabaseAnonKey
        
        if isPlaceholder(url) || isPlaceholder(key) {
            return nil
        }
        
        return (url: url, anonKey: key)
    }
    
    static func getOpenAIKey() -> String? {
        let key = openAIAPIKey
        return isPlaceholder(key) ? nil : key
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    static func printConfigurationStatus() {
        print("🔧 Configuration Status:")
        print("  - Environment: \(buildEnvironment)")
        print("  - Debug Build: \(isDebugBuild)")
        print("  - Stripe: \(isPlaceholder(stripePublishableKey) ? "❌ Placeholder" : "✅ Configured")")
        print("  - Supabase: \(isPlaceholder(supabaseURL) ? "❌ Placeholder" : "✅ Configured")")
        print("  - OpenAI: \(isPlaceholder(openAIAPIKey) ? "❌ Placeholder" : "✅ Configured")")
        
        let warnings = validateConfiguration()
        if !warnings.isEmpty {
            print("⚠️ Warnings:")
            warnings.forEach { print("  - \($0)") }
        }
    }
    #endif
}

// MARK: - Configuration Manager Extension

extension ConfigurationManager {
    
    /// Método seguro para obter configurações com fallbacks
    static func safeGetConfiguration<T>(
        key: String,
        fallback: T,
        validator: ((T) -> Bool)? = nil
    ) -> T {
        
        // Tentar obter do Bundle primeiro
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? T {
            if let validator = validator {
                return validator(value) ? value : fallback
            }
            return value
        }
        
        // Tentar obter de variáveis de ambiente
        if let envValue = ProcessInfo.processInfo.environment[key] as? T {
            if let validator = validator {
                return validator(envValue) ? envValue : fallback
            }
            return envValue
        }
        
        return fallback
    }
}
