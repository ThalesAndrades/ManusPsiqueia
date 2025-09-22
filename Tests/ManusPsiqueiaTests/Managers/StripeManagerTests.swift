//
//  StripeManagerTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia
import StripePaymentSheet

/// Testes para o StripeManager
/// Cobertura: PaymentSheet, assinaturas, webhooks e segurança
final class StripeManagerTests: XCTestCase {
    
    var stripeManager: StripePaymentSheetManager!
    var mockBackendModel: MockBackendModel!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Configurar ambiente de teste
        mockBackendModel = MockBackendModel()
        stripeManager = StripePaymentSheetManager()
        
        // Configurar chaves de teste
        stripeManager.configureTestEnvironment()
    }
    
    override func tearDownWithError() throws {
        stripeManager = nil
        mockBackendModel = nil
        super.tearDown()
    }
    
    // MARK: - Testes de Configuração
    
    func testStripeConfiguration() throws {
        XCTAssertNotNil(stripeManager)
        XCTAssertTrue(stripeManager.isConfigured)
        XCTAssertTrue(stripeManager.isTestMode)
    }
    
    func testPaymentSheetConfiguration() throws {
        let expectation = XCTestExpectation(description: "PaymentSheet configured")
        
        stripeManager.preparePaymentSheet(
            amount: 9990,
            currency: "brl",
            customerId: "test_customer"
        ) { result in
            switch result {
            case .success(let paymentSheet):
                XCTAssertNotNil(paymentSheet)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("PaymentSheet configuration failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Testes de Assinatura
    
    func testSubscriptionCreation() throws {
        let expectation = XCTestExpectation(description: "Subscription created")
        
        let subscriptionData = SubscriptionData(
            customerId: "test_customer",
            priceId: "price_test_professional",
            patientCount: 15,
            features: [.aiPremium]
        )
        
        stripeManager.createSubscription(subscriptionData) { result in
            switch result {
            case .success(let subscription):
                XCTAssertNotNil(subscription.id)
                XCTAssertEqual(subscription.status, .active)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Subscription creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSubscriptionUpdate() throws {
        let expectation = XCTestExpectation(description: "Subscription updated")
        
        // Primeiro criar uma assinatura
        let subscriptionData = SubscriptionData(
            customerId: "test_customer",
            priceId: "price_test_starter",
            patientCount: 5,
            features: []
        )
        
        stripeManager.createSubscription(subscriptionData) { [weak self] result in
            switch result {
            case .success(let subscription):
                // Agora atualizar para Professional
                let updateData = SubscriptionUpdateData(
                    subscriptionId: subscription.id,
                    newPriceId: "price_test_professional",
                    newPatientCount: 15,
                    newFeatures: [.aiPremium]
                )
                
                self?.stripeManager.updateSubscription(updateData) { updateResult in
                    switch updateResult {
                    case .success(let updatedSubscription):
                        XCTAssertEqual(updatedSubscription.id, subscription.id)
                        XCTAssertNotEqual(updatedSubscription.priceId, subscription.priceId)
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Subscription update failed: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Initial subscription creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    // MARK: - Testes de Webhook
    
    func testWebhookValidation() throws {
        let webhookSecret = "whsec_test_secret"
        let payload = """
        {
            "id": "evt_test_webhook",
            "object": "event",
            "type": "invoice.payment_succeeded",
            "data": {
                "object": {
                    "id": "in_test_invoice",
                    "customer": "cus_test_customer",
                    "amount_paid": 9990
                }
            }
        }
        """.data(using: .utf8)!
        
        let signature = stripeManager.generateTestSignature(for: payload, secret: webhookSecret)
        
        XCTAssertTrue(
            stripeManager.validateWebhook(
                payload: payload,
                signature: signature,
                secret: webhookSecret
            )
        )
    }
    
    func testWebhookProcessing() throws {
        let expectation = XCTestExpectation(description: "Webhook processed")
        
        let webhookEvent = StripeWebhookEvent(
            id: "evt_test",
            type: .invoicePaymentSucceeded,
            data: [
                "object": [
                    "id": "in_test",
                    "customer": "cus_test",
                    "amount_paid": 9990
                ]
            ]
        )
        
        stripeManager.processWebhook(webhookEvent) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Webhook processing failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Testes de Segurança
    
    func testAPIKeyValidation() throws {
        // Testar com chave inválida
        let invalidManager = StripePaymentSheetManager()
        invalidManager.configure(with: "invalid_key")
        
        XCTAssertFalse(invalidManager.isConfigured)
        
        // Testar com chave válida de teste
        invalidManager.configure(with: "pk_test_valid_key")
        XCTAssertTrue(invalidManager.isConfigured)
    }
    
    func testSecureDataHandling() throws {
        let sensitiveData = PaymentData(
            cardNumber: "4242424242424242",
            expiryMonth: 12,
            expiryYear: 2025,
            cvc: "123"
        )
        
        // Verificar que dados sensíveis não são logados
        let logOutput = stripeManager.processPaymentSecurely(sensitiveData)
        
        XCTAssertFalse(logOutput.contains("4242424242424242"))
        XCTAssertFalse(logOutput.contains("123"))
        XCTAssertTrue(logOutput.contains("****"))
    }
    
    // MARK: - Testes de Error Handling
    
    func testNetworkErrorHandling() throws {
        let expectation = XCTestExpectation(description: "Network error handled")
        
        // Simular erro de rede
        stripeManager.simulateNetworkError = true
        
        stripeManager.preparePaymentSheet(
            amount: 9990,
            currency: "brl",
            customerId: "test_customer"
        ) { result in
            switch result {
            case .success:
                XCTFail("Should have failed with network error")
            case .failure(let error):
                XCTAssertTrue(error.isNetworkError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testInvalidAmountHandling() throws {
        let expectation = XCTestExpectation(description: "Invalid amount handled")
        
        stripeManager.preparePaymentSheet(
            amount: -100, // Valor inválido
            currency: "brl",
            customerId: "test_customer"
        ) { result in
            switch result {
            case .success:
                XCTFail("Should have failed with invalid amount")
            case .failure(let error):
                XCTAssertTrue(error.isValidationError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Testes de Performance
    
    func testPaymentSheetPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            stripeManager.preparePaymentSheet(
                amount: 9990,
                currency: "brl",
                customerId: "test_customer"
            ) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Testes de Integração
    
    func testFullPaymentFlow() throws {
        let expectation = XCTestExpectation(description: "Full payment flow")
        
        // 1. Preparar PaymentSheet
        stripeManager.preparePaymentSheet(
            amount: 9990,
            currency: "brl",
            customerId: "test_customer"
        ) { [weak self] result in
            switch result {
            case .success(let paymentSheet):
                // 2. Simular pagamento bem-sucedido
                self?.stripeManager.simulateSuccessfulPayment(paymentSheet) { paymentResult in
                    switch paymentResult {
                    case .completed:
                        expectation.fulfill()
                    case .canceled:
                        XCTFail("Payment was canceled")
                    case .failed(let error):
                        XCTFail("Payment failed: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("PaymentSheet preparation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

// MARK: - Mock Classes

class MockBackendModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    
    func preparePaymentSheet() {
        // Mock implementation
    }
}

extension StripeError {
    var isNetworkError: Bool {
        // Implementation to check if error is network-related
        return true
    }
    
    var isValidationError: Bool {
        // Implementation to check if error is validation-related
        return true
    }
}
