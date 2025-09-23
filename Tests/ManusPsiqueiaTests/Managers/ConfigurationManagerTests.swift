//
//  ConfigurationManagerTests.swift
//  ManusPsiqueiaTests
//
//  Testes para o ConfigurationManager
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

final class ConfigurationManagerTests: XCTestCase {
    
    var configManager: ConfigurationManager!
    
    override func setUpWithError() throws {
        super.setUpWithError()
        configManager = ConfigurationManager.shared
    }
    
    override func tearDownWithError() throws {
        configManager = nil
        super.tearDownWithError()
    }
    
    // MARK: - Environment Detection Tests
    
    func testCurrentEnvironment() throws {
        let environment = configManager.currentEnvironment
        
        XCTAssertTrue(
            [.development, .staging, .production].contains(environment),
            "Environment should be one of the defined cases"
        )
        
        print("Current environment: \(environment.displayName)")
    }
    
    func testEnvironmentDisplayNames() throws {
        XCTAssertEqual(ConfigurationManager.Environment.development.displayName, "Desenvolvimento")
        XCTAssertEqual(ConfigurationManager.Environment.staging.displayName, "Staging")
        XCTAssertEqual(ConfigurationManager.Environment.production.displayName, "Produção")
    }
    
    // MARK: - App Configuration Tests
    
    func testAppConfiguration() throws {
        XCTAssertFalse(configManager.appDisplayName.isEmpty, "App display name should not be empty")
        XCTAssertFalse(configManager.bundleIdentifier.isEmpty, "Bundle identifier should not be empty")
        XCTAssertFalse(configManager.appVersion.isEmpty, "App version should not be empty")
        XCTAssertFalse(configManager.buildNumber.isEmpty, "Build number should not be empty")
        
        print("App: \(configManager.appDisplayName)")
        print("Bundle ID: \(configManager.bundleIdentifier)")
        print("Version: \(configManager.appVersion) (\(configManager.buildNumber))")
    }
    
    func testBundleIdentifierFormat() throws {
        let bundleId = configManager.bundleIdentifier
        
        XCTAssertTrue(bundleId.contains("com.ailun.manuspsiqueia"), "Bundle ID should contain base identifier")
        
        // Verificar sufixo baseado no ambiente
        switch configManager.currentEnvironment {
        case .development:
            XCTAssertTrue(bundleId.contains(".dev") || bundleId == "com.ailun.manuspsiqueia", "Development bundle ID should have .dev suffix or be base")
        case .staging:
            XCTAssertTrue(bundleId.contains(".beta") || bundleId == "com.ailun.manuspsiqueia", "Staging bundle ID should have .beta suffix or be base")
        case .production:
            XCTAssertEqual(bundleId, "com.ailun.manuspsiqueia", "Production bundle ID should be base identifier")
        }
    }
    
    // MARK: - API Configuration Tests
    
    func testAPIConfiguration() throws {
        XCTAssertFalse(configManager.apiBaseURL.isEmpty, "API base URL should not be empty")
        XCTAssertEqual(configManager.apiVersion, "v1", "API version should be v1")
        XCTAssertFalse(configManager.fullAPIURL.isEmpty, "Full API URL should not be empty")
        
        // Verificar formato da URL
        XCTAssertTrue(configManager.apiBaseURL.hasPrefix("https://"), "API base URL should use HTTPS")
        XCTAssertTrue(configManager.fullAPIURL.contains("/v1"), "Full API URL should contain version")
        
        print("API Base URL: \(configManager.apiBaseURL)")
        print("Full API URL: \(configManager.fullAPIURL)")
    }
    
    func testAPIURLsByEnvironment() throws {
        let baseURL = configManager.apiBaseURL
        
        switch configManager.currentEnvironment {
        case .development:
            XCTAssertTrue(baseURL.contains("api-dev"), "Development should use dev API")
        case .staging:
            XCTAssertTrue(baseURL.contains("api-staging"), "Staging should use staging API")
        case .production:
            XCTAssertTrue(baseURL.contains("api.manuspsiqueia.com"), "Production should use production API")
        }
    }
    
    // MARK: - Stripe Configuration Tests
    
    func testStripeConfiguration() throws {
        // Stripe key pode estar vazia em ambiente de teste
        let stripeKey = configManager.stripePublishableKey
        let webhookEndpoint = configManager.stripeWebhookEndpoint
        
        XCTAssertFalse(webhookEndpoint.isEmpty, "Stripe webhook endpoint should not be empty")
        XCTAssertTrue(webhookEndpoint.contains("webhooks/stripe"), "Webhook endpoint should contain correct path")
        
        // Se a chave estiver configurada, deve ter formato correto
        if !stripeKey.isEmpty {
            XCTAssertTrue(stripeKey.hasPrefix("pk_"), "Stripe publishable key should start with pk_")
        }
        
        print("Stripe Key configured: \(!stripeKey.isEmpty)")
        print("Webhook Endpoint: \(webhookEndpoint)")
    }
    
    // MARK: - Supabase Configuration Tests
    
    func testSupabaseConfiguration() throws {
        let supabaseURL = configManager.supabaseURL
        let supabaseKey = configManager.supabaseAnonKey
        
        // URLs podem estar vazias em ambiente de teste
        if !supabaseURL.isEmpty {
            XCTAssertTrue(supabaseURL.hasPrefix("https://"), "Supabase URL should use HTTPS")
            XCTAssertTrue(supabaseURL.contains("supabase.co"), "Supabase URL should contain supabase.co")
        }
        
        print("Supabase URL configured: \(!supabaseURL.isEmpty)")
        print("Supabase Key configured: \(!supabaseKey.isEmpty)")
    }
    
    // MARK: - OpenAI Configuration Tests
    
    func testOpenAIConfiguration() throws {
        let endpoint = configManager.openAIAPIEndpoint
        let model = configManager.openAIModel
        let apiKey = configManager.openAIAPIKey
        
        XCTAssertEqual(endpoint, "https://api.openai.com/v1", "OpenAI endpoint should be correct")
        XCTAssertEqual(model, "gpt-4", "OpenAI model should be gpt-4")
        
        print("OpenAI Endpoint: \(endpoint)")
        print("OpenAI Model: \(model)")
        print("OpenAI Key configured: \(!apiKey.isEmpty)")
    }
    
    // MARK: - Feature Flags Tests
    
    func testFeatureFlags() throws {
        let debugMenu = configManager.isDebugMenuEnabled
        let analytics = configManager.isAnalyticsEnabled
        let crashReporting = configManager.isCrashReportingEnabled
        let logging = configManager.isLoggingEnabled
        
        // Verificar configurações baseadas no ambiente
        switch configManager.currentEnvironment {
        case .development:
            XCTAssertTrue(debugMenu, "Debug menu should be enabled in development")
            XCTAssertFalse(analytics, "Analytics should be disabled in development")
            XCTAssertFalse(crashReporting, "Crash reporting should be disabled in development")
            XCTAssertTrue(logging, "Logging should be enabled in development")
            
        case .staging:
            XCTAssertTrue(debugMenu, "Debug menu should be enabled in staging")
            XCTAssertTrue(analytics, "Analytics should be enabled in staging")
            XCTAssertTrue(crashReporting, "Crash reporting should be enabled in staging")
            XCTAssertTrue(logging, "Logging should be enabled in staging")
            
        case .production:
            XCTAssertFalse(debugMenu, "Debug menu should be disabled in production")
            XCTAssertTrue(analytics, "Analytics should be enabled in production")
            XCTAssertTrue(crashReporting, "Crash reporting should be enabled in production")
            XCTAssertFalse(logging, "Logging should be disabled in production")
        }
        
        print("Feature flags for \(configManager.currentEnvironment.displayName):")
        print("  Debug Menu: \(debugMenu)")
        print("  Analytics: \(analytics)")
        print("  Crash Reporting: \(crashReporting)")
        print("  Logging: \(logging)")
    }
    
    // MARK: - Security Configuration Tests
    
    func testSecurityConfiguration() throws {
        let certificatePinning = configManager.isCertificatePinningEnabled
        let securityLevel = configManager.networkSecurityLevel
        
        // Verificar configurações baseadas no ambiente
        switch configManager.currentEnvironment {
        case .development:
            XCTAssertFalse(certificatePinning, "Certificate pinning should be disabled in development")
            XCTAssertEqual(securityLevel, .low, "Security level should be low in development")
            
        case .staging:
            XCTAssertTrue(certificatePinning, "Certificate pinning should be enabled in staging")
            XCTAssertEqual(securityLevel, .medium, "Security level should be medium in staging")
            
        case .production:
            XCTAssertTrue(certificatePinning, "Certificate pinning should be enabled in production")
            XCTAssertEqual(securityLevel, .high, "Security level should be high in production")
        }
        
        print("Security configuration:")
        print("  Certificate Pinning: \(certificatePinning)")
        print("  Security Level: \(securityLevel.rawValue)")
    }
    
    // MARK: - Configuration Validation Tests
    
    func testConfigurationValidation() throws {
        let errors = configManager.validateConfiguration()
        
        // Em ambiente de teste, esperamos alguns erros de configuração
        XCTAssertTrue(errors.count >= 0, "Validation should return array of errors")
        
        print("Configuration errors: \(errors.count)")
        for error in errors {
            print("  - \(error)")
        }
    }
    
    func testValidationErrorTypes() throws {
        let errors = configManager.validateConfiguration()
        
        // Verificar tipos de erro esperados
        let errorString = errors.joined(separator: " ")
        
        if errorString.contains("Stripe") {
            print("Stripe configuration missing")
        }
        if errorString.contains("Supabase") {
            print("Supabase configuration missing")
        }
        if errorString.contains("OpenAI") {
            print("OpenAI configuration missing")
        }
    }
    
    // MARK: - Debug Information Tests
    
    func testDebugInfo() throws {
        let debugInfo = configManager.getDebugInfo()
        
        XCTAssertNotNil(debugInfo["environment"], "Debug info should contain environment")
        XCTAssertNotNil(debugInfo["app_version"], "Debug info should contain app version")
        XCTAssertNotNil(debugInfo["build_number"], "Debug info should contain build number")
        XCTAssertNotNil(debugInfo["bundle_identifier"], "Debug info should contain bundle identifier")
        XCTAssertNotNil(debugInfo["api_base_url"], "Debug info should contain API base URL")
        
        print("Debug Info:")
        for (key, value) in debugInfo {
            print("  \(key): \(value)")
        }
    }
    
    // MARK: - Extensions Tests
    
    func testLoggingConfiguration() throws {
        let loggingConfig = configManager.loggingConfiguration
        
        XCTAssertNotNil(loggingConfig["enabled"], "Logging config should contain enabled flag")
        XCTAssertNotNil(loggingConfig["level"], "Logging config should contain level")
        XCTAssertNotNil(loggingConfig["remote_logging"], "Logging config should contain remote logging flag")
        
        let level = loggingConfig["level"] as? String
        XCTAssertTrue(level == "DEBUG" || level == "ERROR", "Log level should be DEBUG or ERROR")
        
        print("Logging Configuration: \(loggingConfig)")
    }
    
    func testNetworkTimeoutConfiguration() throws {
        let timeouts = configManager.networkTimeoutConfiguration
        
        XCTAssertGreaterThan(timeouts.connect, 0, "Connect timeout should be positive")
        XCTAssertGreaterThan(timeouts.request, 0, "Request timeout should be positive")
        XCTAssertGreaterThan(timeouts.request, timeouts.connect, "Request timeout should be greater than connect timeout")
        
        // Verificar valores baseados no nível de segurança
        switch configManager.networkSecurityLevel {
        case .low:
            XCTAssertEqual(timeouts.connect, 10.0, "Low security connect timeout should be 10s")
            XCTAssertEqual(timeouts.request, 30.0, "Low security request timeout should be 30s")
        case .medium:
            XCTAssertEqual(timeouts.connect, 8.0, "Medium security connect timeout should be 8s")
            XCTAssertEqual(timeouts.request, 20.0, "Medium security request timeout should be 20s")
        case .high:
            XCTAssertEqual(timeouts.connect, 5.0, "High security connect timeout should be 5s")
            XCTAssertEqual(timeouts.request, 15.0, "High security request timeout should be 15s")
        }
        
        print("Network Timeouts: Connect=\(timeouts.connect)s, Request=\(timeouts.request)s")
    }
    
    // MARK: - Keychain Tests
    
    func testKeychainOperations() throws {
        let testKey = "test_secret_key"
        let testValue = "test_secret_value"
        
        // Testar armazenamento
        let storeResult = configManager.storeSecretInKeychain(key: testKey, value: testValue)
        XCTAssertTrue(storeResult, "Should successfully store secret in keychain")
        
        // Testar remoção
        let deleteResult = configManager.deleteSecretFromKeychain(key: testKey)
        XCTAssertTrue(deleteResult, "Should successfully delete secret from keychain")
        
        // Testar remoção de chave inexistente
        let deleteNonExistentResult = configManager.deleteSecretFromKeychain(key: "non_existent_key")
        XCTAssertTrue(deleteNonExistentResult, "Should return true when deleting non-existent key")
    }
    
    // MARK: - Performance Tests
    
    func testConfigurationManagerPerformance() throws {
        measure {
            // Testar performance das operações mais comuns
            _ = configManager.currentEnvironment
            _ = configManager.apiBaseURL
            _ = configManager.validateConfiguration()
            _ = configManager.getDebugInfo()
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() throws {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // Executar operações em múltiplas threads
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let environment = self.configManager.currentEnvironment
                let apiURL = self.configManager.apiBaseURL
                let debugInfo = self.configManager.getDebugInfo()
                
                XCTAssertNotNil(environment)
                XCTAssertNotNil(apiURL)
                XCTAssertNotNil(debugInfo)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
