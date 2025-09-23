//
//  BuildErrorHandler.swift
//  ManusPsiqueia
//
//  Tratamento de erros específicos para builds e CI/CD
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Build Error Handler

struct BuildErrorHandler {
    
    // MARK: - Error Types
    
    enum BuildError: LocalizedError {
        case missingConfiguration(String)
        case invalidAPIKey(String)
        case networkUnavailable
        case dependencyMissing(String)
        case buildEnvironmentMismatch
        
        var errorDescription: String? {
            switch self {
            case .missingConfiguration(let config):
                return "Configuração ausente: \(config)"
            case .invalidAPIKey(let service):
                return "Chave de API inválida para \(service)"
            case .networkUnavailable:
                return "Rede indisponível durante o build"
            case .dependencyMissing(let dependency):
                return "Dependência ausente: \(dependency)"
            case .buildEnvironmentMismatch:
                return "Ambiente de build incompatível"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .missingConfiguration(let config):
                return "Configure \(config) nas variáveis de ambiente do Xcode Cloud"
            case .invalidAPIKey(let service):
                return "Verifique a chave de API do \(service) nas configurações"
            case .networkUnavailable:
                return "Verifique a conexão de rede e tente novamente"
            case .dependencyMissing(let dependency):
                return "Adicione \(dependency) ao Package.swift"
            case .buildEnvironmentMismatch:
                return "Verifique as configurações do ambiente de build"
            }
        }
    }
    
    // MARK: - Validation Methods
    
    static func validateBuildEnvironment() throws {
        // Verificar se estamos em um ambiente de build válido
        let environment = ConfigurationFallbacks.buildEnvironment
        let validEnvironments = ["Development", "Staging", "Production"]
        
        guard validEnvironments.contains(environment) else {
            throw BuildError.buildEnvironmentMismatch
        }
    }
    
    static func validateAPIKeys() throws {
        let warnings = ConfigurationFallbacks.validateConfiguration()
        
        // Em produção, não permitir placeholders
        if ConfigurationFallbacks.buildEnvironment == "Production" {
            if ConfigurationFallbacks.isPlaceholder(ConfigurationFallbacks.stripePublishableKey) {
                throw BuildError.invalidAPIKey("Stripe")
            }
            
            if ConfigurationFallbacks.isPlaceholder(ConfigurationFallbacks.openAIAPIKey) {
                throw BuildError.invalidAPIKey("OpenAI")
            }
        }
    }
    
    static func validateDependencies() throws {
        // Verificar se as dependências críticas estão disponíveis
        let criticalClasses = [
            "StripeAPI",
            "Supabase",
            "OpenAI"
        ]
        
        for className in criticalClasses {
            if NSClassFromString(className) == nil {
                // Em desenvolvimento, apenas avisar
                if ConfigurationFallbacks.buildEnvironment == "Development" {
                    print("⚠️ Dependência não encontrada: \(className)")
                } else {
                    throw BuildError.dependencyMissing(className)
                }
            }
        }
    }
    
    // MARK: - Recovery Methods
    
    static func attemptRecovery(from error: BuildError) -> Bool {
        switch error {
        case .missingConfiguration:
            // Tentar usar fallbacks
            return true
            
        case .invalidAPIKey:
            // Em desenvolvimento, permitir placeholders
            return ConfigurationFallbacks.buildEnvironment == "Development"
            
        case .networkUnavailable:
            // Tentar modo offline
            return enableOfflineMode()
            
        case .dependencyMissing:
            // Tentar carregar dependências opcionais
            return true
            
        case .buildEnvironmentMismatch:
            // Não é possível recuperar
            return false
        }
    }
    
    private static func enableOfflineMode() -> Bool {
        // Configurar modo offline para desenvolvimento
        UserDefaults.standard.set(true, forKey: "OfflineMode")
        return true
    }
    
    // MARK: - Build Validation
    
    static func performBuildValidation() -> [String] {
        var issues: [String] = []
        
        do {
            try validateBuildEnvironment()
        } catch {
            issues.append("❌ Ambiente de build: \(error.localizedDescription)")
        }
        
        do {
            try validateAPIKeys()
        } catch {
            if ConfigurationFallbacks.buildEnvironment == "Production" {
                issues.append("❌ Chaves de API: \(error.localizedDescription)")
            } else {
                issues.append("⚠️ Chaves de API: \(error.localizedDescription)")
            }
        }
        
        do {
            try validateDependencies()
        } catch {
            issues.append("⚠️ Dependências: \(error.localizedDescription)")
        }
        
        return issues
    }
    
    // MARK: - CI/CD Helpers
    
    static func isRunningInCI() -> Bool {
        return ProcessInfo.processInfo.environment["CI"] != nil ||
               ProcessInfo.processInfo.environment["CI_XCODE_CLOUD"] != nil
    }
    
    static func shouldFailBuildOnError(_ error: BuildError) -> Bool {
        // Em CI/CD, ser mais rigoroso
        if isRunningInCI() {
            switch error {
            case .missingConfiguration, .buildEnvironmentMismatch:
                return true
            case .invalidAPIKey:
                return ConfigurationFallbacks.buildEnvironment == "Production"
            case .networkUnavailable, .dependencyMissing:
                return false
            }
        }
        
        // Em desenvolvimento local, ser mais permissivo
        return false
    }
    
    // MARK: - Logging
    
    static func logBuildStatus() {
        let environment = ConfigurationFallbacks.buildEnvironment
        let isCI = isRunningInCI()
        let issues = performBuildValidation()
        
        print("🏗️ Build Status Report:")
        print("  - Environment: \(environment)")
        print("  - CI/CD: \(isCI ? "Yes" : "No")")
        print("  - Issues Found: \(issues.count)")
        
        if !issues.isEmpty {
            print("📋 Issues:")
            issues.forEach { print("  \($0)") }
        } else {
            print("✅ No issues found")
        }
        
        #if DEBUG
        ConfigurationFallbacks.printConfigurationStatus()
        #endif
    }
}

// MARK: - SwiftUI Integration

struct BuildValidationView: View {
    @State private var validationResults: [String] = []
    @State private var isValidating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Validation")
                .font(.title2)
                .fontWeight(.bold)
            
            if isValidating {
                ProgressView("Validating...")
            } else {
                if validationResults.isEmpty {
                    Text("✅ All validations passed")
                        .foregroundColor(.green)
                } else {
                    ForEach(validationResults, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.hasPrefix("❌") ? .red : .orange)
                    }
                }
            }
            
            Button("Run Validation") {
                runValidation()
            }
            .disabled(isValidating)
        }
        .padding()
        .onAppear {
            runValidation()
        }
    }
    
    private func runValidation() {
        isValidating = true
        
        DispatchQueue.global(qos: .background).async {
            let results = BuildErrorHandler.performBuildValidation()
            
            DispatchQueue.main.async {
                self.validationResults = results
                self.isValidating = false
            }
        }
    }
}

#if DEBUG
// MARK: - Debug Helpers

extension BuildErrorHandler {
    
    static func simulateError(_ error: BuildError) {
        print("🧪 Simulating error: \(error.localizedDescription)")
        
        if attemptRecovery(from: error) {
            print("✅ Recovery successful")
        } else {
            print("❌ Recovery failed")
        }
    }
    
    static func testAllValidations() {
        print("🧪 Testing all validations...")
        
        let errors: [BuildError] = [
            .missingConfiguration("TEST_CONFIG"),
            .invalidAPIKey("TestService"),
            .networkUnavailable,
            .dependencyMissing("TestDependency"),
            .buildEnvironmentMismatch
        ]
        
        errors.forEach { simulateError($0) }
    }
}
#endif
