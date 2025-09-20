//
//  PaymentTests.swift
//  ManusPsiqueiaTests
//
//  Created by Thales Andrades on 2024
//  Copyright © 2024 ManusPsiqueia. All rights reserved.
//

import XCTest
import Stripe
@testable import ManusPsiqueia

@MainActor
final class PaymentTests: XCTestCase {
    
    var stripeManager: StripeManager!
    var subscriptionService: SubscriptionService!
    var securityManager: SecurityManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Configurar ambiente de teste
        stripeManager = StripeManager.shared
        subscriptionService = SubscriptionService.shared
        securityManager = SecurityManager.shared
        
        // Configurar Stripe para testes
        await stripeManager.setupStripe()
    }
    
    override func tearDown() async throws {
        stripeManager = nil
        subscriptionService = nil
        securityManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Security Tests
    
    func testEncryptionDecryption() async throws {
        let originalData = "Dados sensíveis do paciente".data(using: .utf8)!
        
        do {
            let encryptedData = try await securityManager.encryptData(originalData)
            XCTAssertNotEqual(encryptedData, originalData)
            
            let decryptedData = try await securityManager.decryptData(encryptedData)
            XCTAssertEqual(decryptedData, originalData)
        } catch {
            XCTFail("Encryption/Decryption failed: \(error)")
        }
    }
    
    func testDataSanitization() async throws {
        let sensitiveData = """
        Email: user@example.com
        Cartão: 4242-4242-4242-4242
        CPF: 123.456.789-00
        """
        
        let sanitizedData = securityManager.sanitizeData(sensitiveData)
        
        XCTAssertFalse(sanitizedData.contains("user@example.com"))
        XCTAssertFalse(sanitizedData.contains("4242-4242-4242-4242"))
        XCTAssertFalse(sanitizedData.contains("123.456.789-00"))
        
        XCTAssertTrue(sanitizedData.contains("***@***.***"))
        XCTAssertTrue(sanitizedData.contains("****-****-****-****"))
        XCTAssertTrue(sanitizedData.contains("***.***.***-**"))
    }
    
    func testSecurityComplianceValidation() async throws {
        let report = await securityManager.validateSecurityCompliance()
        
        XCTAssertTrue(report.encryptionEnabled)
        XCTAssertTrue(report.certificatePinningEnabled)
        XCTAssertTrue(report.auditLoggingEnabled)
        XCTAssertGreaterThan(report.overallCompliance, 0.8) // Pelo menos 80% de compliance
    }
    
    // MARK: - Subscription Tests
    
    func testSubscriptionPlansAvailability() async throws {
        XCTAssertFalse(subscriptionService.availablePlans.isEmpty)
        XCTAssertEqual(subscriptionService.availablePlans.count, 4)
        
        let planIds = subscriptionService.availablePlans.map { $0.id }
        XCTAssertTrue(planIds.contains("starter"))
        XCTAssertTrue(planIds.contains("professional"))
        XCTAssertTrue(planIds.contains("expert"))
        XCTAssertTrue(planIds.contains("enterprise"))
    }
    
    func testDynamicPricing() async throws {
        let starterPlan = subscriptionService.availablePlans.first { $0.id == "starter" }!
        
        // Teste preço base
        let basePrice = subscriptionService.calculateDynamicPrice(
            for: "starter",
            patientCount: 5,
            additionalFeatures: []
        )
        XCTAssertEqual(basePrice, starterPlan.basePrice)
        
        // Teste preço com pacientes adicionais
        let priceWithExtraPatients = subscriptionService.calculateDynamicPrice(
            for: "starter",
            patientCount: 15,
            additionalFeatures: []
        )
        XCTAssertGreaterThan(priceWithExtraPatients, basePrice)
        
        // Teste preço com recursos adicionais
        let priceWithFeatures = subscriptionService.calculateDynamicPrice(
            for: "starter",
            patientCount: 5,
            additionalFeatures: [.aiInsights]
        )
        XCTAssertGreaterThan(priceWithFeatures, basePrice)
    }
    
    // MARK: - Compliance Tests
    
    func testPCIDSSCompliance() async throws {
        // Verificar requisitos específicos do PCI DSS
        
        // Requirement 3: Protect stored cardholder data
        XCTAssertTrue(securityManager.encryptionStatus == .enabled)
        
        // Requirement 4: Encrypt transmission of cardholder data
        let report = await securityManager.validateSecurityCompliance()
        XCTAssertTrue(report.certificatePinningEnabled)
        
        // Requirement 8: Identify and authenticate access
        XCTAssertTrue(report.biometricAuthEnabled || securityManager.biometricAuthEnabled)
        
        // Requirement 10: Track and monitor all access
        XCTAssertTrue(report.auditLoggingEnabled)
        
        // Overall PCI DSS compliance
        XCTAssertTrue(report.pciDssCompliant)
    }
    
    func testLGPDCompliance() async throws {
        // Verificar compliance com LGPD
        
        // Dados devem ser criptografados
        let sensitiveData = "Dados pessoais do paciente".data(using: .utf8)!
        let encryptedData = try await securityManager.encryptData(sensitiveData)
        XCTAssertNotEqual(encryptedData, sensitiveData)
        
        // Dados devem ser sanitizados em logs
        let personalData = "Email: paciente@email.com, CPF: 123.456.789-00"
        let sanitizedData = securityManager.sanitizeData(personalData)
        XCTAssertFalse(sanitizedData.contains("paciente@email.com"))
        XCTAssertFalse(sanitizedData.contains("123.456.789-00"))
    }
}
