//
//  WebhookManagerTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
import CryptoKit
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

@MainActor
class WebhookManagerTests: XCTestCase {
    var webhookManager: WebhookManager!
    
    override func setUp() {
        super.setUp()
        webhookManager = WebhookManager.shared
        
        // Reset webhook manager state before each test
        webhookManager.processingQueue.removeAll()
        webhookManager.processedEvents.removeAll()
        webhookManager.isProcessing = false
        webhookManager.lastProcessedEvent = nil
    }
    
    override func tearDown() {
        webhookManager = nil
        super.tearDown()
    }
    
    // MARK: - Webhook Validation Tests
    
    func testWebhookSignatureValidation() {
        // Given
        let webhookSecret = "whsec_test_secret_123"
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
        
        // When
        let signature = webhookManager.generateTestSignature(for: payload, secret: webhookSecret)
        let isValid = webhookManager.validateWebhook(
            payload: payload,
            signature: signature,
            secret: webhookSecret
        )
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testWebhookSignatureValidationFailure() {
        // Given
        let webhookSecret = "whsec_test_secret_123"
        let payload = "test payload".data(using: .utf8)!
        let invalidSignature = "t=123456789,v1=invalid_signature"
        
        // When
        let isValid = webhookManager.validateWebhook(
            payload: payload,
            signature: invalidSignature,
            secret: webhookSecret
        )
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testWebhookTimestampValidation() {
        // Given
        let webhookSecret = "whsec_test_secret_123"
        let payload = "test payload".data(using: .utf8)!
        
        // Create signature with old timestamp (more than 5 minutes ago)
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 600) // 10 minutes ago
        let signedPayload = "\(oldTimestamp).test payload"
        let key = SymmetricKey(data: webhookSecret.data(using: .utf8)!)
        let signature_bytes = HMAC<SHA256>.authenticationCode(for: signedPayload.data(using: .utf8)!, using: key)
        let signature = Data(signature_bytes).map { String(format: "%02x", $0) }.joined()
        let oldSignature = "t=\(oldTimestamp),v1=\(signature)"
        
        // When
        let isValid = webhookManager.validateWebhook(
            payload: payload,
            signature: oldSignature,
            secret: webhookSecret
        )
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Event Processing Tests
    
    func testPaymentSucceededEventProcessing() async {
        // Given
        let eventData: [String: Any] = [
            "object": [
                "id": "in_test_invoice",
                "customer": "cus_test_customer",
                "amount_paid": 9990
            ]
        ]
        
        let event = StripeWebhookEvent(
            id: "evt_test_payment_succeeded",
            type: .invoicePaymentSucceeded,
            created: Int(Date().timeIntervalSince1970),
            data: eventData,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("cus_test_customer"))
            XCTAssertTrue(webhookManager.processedEvents.contains(event.id))
            XCTAssertEqual(webhookManager.lastProcessedEvent?.id, event.id)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    func testPaymentFailedEventProcessing() async {
        // Given
        let eventData: [String: Any] = [
            "object": [
                "id": "in_test_invoice",
                "customer": "cus_test_customer",
                "last_payment_error": [
                    "message": "Your card was declined."
                ]
            ]
        ]
        
        let event = StripeWebhookEvent(
            id: "evt_test_payment_failed",
            type: .invoicePaymentFailed,
            created: Int(Date().timeIntervalSince1970),
            data: eventData,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("cus_test_customer"))
            XCTAssertTrue(webhookManager.processedEvents.contains(event.id))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    func testSubscriptionCreatedEventProcessing() async {
        // Given
        let eventData: [String: Any] = [
            "object": [
                "id": "sub_test_subscription",
                "customer": "cus_test_customer",
                "status": "active"
            ]
        ]
        
        let event = StripeWebhookEvent(
            id: "evt_test_subscription_created",
            type: .customerSubscriptionCreated,
            created: Int(Date().timeIntervalSince1970),
            data: eventData,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("sub_test_subscription"))
            XCTAssertTrue(webhookManager.processedEvents.contains(event.id))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    func testSubscriptionUpdatedEventProcessing() async {
        // Given
        let eventData: [String: Any] = [
            "object": [
                "id": "sub_test_subscription",
                "customer": "cus_test_customer",
                "status": "active"
            ]
        ]
        
        let event = StripeWebhookEvent(
            id: "evt_test_subscription_updated",
            type: .customerSubscriptionUpdated,
            created: Int(Date().timeIntervalSince1970),
            data: eventData,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("sub_test_subscription"))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    func testSubscriptionCancelledEventProcessing() async {
        // Given
        let eventData: [String: Any] = [
            "object": [
                "id": "sub_test_subscription",
                "customer": "cus_test_customer",
                "status": "canceled"
            ]
        ]
        
        let event = StripeWebhookEvent(
            id: "evt_test_subscription_cancelled",
            type: .customerSubscriptionDeleted,
            created: Int(Date().timeIntervalSince1970),
            data: eventData,
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("sub_test_subscription"))
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    // MARK: - Duplicate Event Tests
    
    func testDuplicateEventProcessing() async {
        // Given
        let event = webhookManager.createTestWebhookEvent(
            type: .invoicePaymentSucceeded,
            data: [
                "object": [
                    "id": "in_test_invoice",
                    "customer": "cus_test_customer",
                    "amount_paid": 9990
                ]
            ]
        )
        
        // Process the event once
        _ = await webhookManager.processWebhook(event)
        
        // When - process the same event again
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .ignored(let reason):
            XCTAssertEqual(reason, "Duplicate event")
        case .success, .failure:
            XCTFail("Expected ignored result for duplicate event")
        }
    }
    
    // MARK: - Retry Mechanism Tests
    
    func testWebhookRetryMechanism() async {
        // Given
        let event = webhookManager.createTestWebhookEvent(
            type: .invoicePaymentSucceeded,
            data: [:] // Invalid data to trigger failure
        )
        
        // When
        let result = await webhookManager.processWebhookWithRetry(event)
        
        // Then
        switch result {
        case .failure:
            // Expected to fail due to invalid data
            XCTAssertTrue(true)
        case .success, .ignored:
            XCTFail("Expected failure due to invalid event data")
        }
    }
    
    // MARK: - Event Creation Tests
    
    func testCreateTestWebhookEvent() {
        // Given
        let eventType = WebhookEventType.customerCreated
        let testData = ["customer_id": "cus_test_123"]
        
        // When
        let event = webhookManager.createTestWebhookEvent(type: eventType, data: testData)
        
        // Then
        XCTAssertEqual(event.type, eventType)
        XCTAssertEqual(event.data["customer_id"] as? String, "cus_test_123")
        XCTAssertTrue(event.id.hasPrefix("evt_test_"))
        XCTAssertEqual(event.livemode, false)
    }
    
    func testGenerateTestSignature() {
        // Given
        let payload = "test payload".data(using: .utf8)!
        let secret = "whsec_test_secret"
        
        // When
        let signature = webhookManager.generateTestSignature(for: payload, secret: secret)
        
        // Then
        XCTAssertTrue(signature.hasPrefix("t="))
        XCTAssertTrue(signature.contains(",v1="))
        
        // Validate the generated signature
        let isValid = webhookManager.validateWebhook(
            payload: payload,
            signature: signature,
            secret: secret
        )
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidEventDataHandling() async {
        // Given
        let event = StripeWebhookEvent(
            id: "evt_test_invalid",
            type: .invoicePaymentSucceeded,
            created: Int(Date().timeIntervalSince1970),
            data: [:], // Empty data should cause failure
            livemode: false,
            pendingWebhooks: 1,
            request: nil
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .failure(let error):
            XCTAssertTrue(error is WebhookError)
        case .success, .ignored:
            XCTFail("Expected failure due to invalid event data")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testProcessedEventsMemoryManagement() async {
        // Given - process more than 1000 events
        for i in 0..<1200 {
            let event = webhookManager.createTestWebhookEvent(
                type: .customerCreated,
                data: ["test_index": i]
            )
            
            // Manually add to processed events to simulate processing
            webhookManager.processedEvents.append(event.id)
        }
        
        // When - trigger cleanup by processing one more event
        let finalEvent = webhookManager.createTestWebhookEvent(
            type: .customerCreated,
            data: ["customer_id": "cus_final"]
        )
        _ = await webhookManager.processWebhook(finalEvent)
        
        // Then - should not exceed 1000 events
        XCTAssertLessThanOrEqual(webhookManager.processedEvents.count, 1000)
    }
    
    // MARK: - Flow Integration Tests
    
    func testWebhookFlowIntegration() async {
        // Given
        let flowManager = FlowManager.shared
        flowManager.startFlow(.subscription)
        
        let event = webhookManager.createTestWebhookEvent(
            type: .invoicePaymentSucceeded,
            data: [
                "object": [
                    "id": "in_test_invoice",
                    "customer": "cus_test_customer",
                    "amount_paid": 9990
                ]
            ]
        )
        
        // When
        let result = await webhookManager.processWebhook(event)
        
        // Then
        switch result {
        case .success:
            // Flow should be completed by webhook processing
            XCTAssertEqual(flowManager.flowState, .completed)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        case .ignored(let reason):
            XCTFail("Expected success but got ignored: \(reason)")
        }
    }
    
    // MARK: - Event Type Display Name Tests
    
    func testWebhookEventTypeDisplayNames() {
        // Test all event types have proper display names
        for eventType in WebhookEventType.allCases {
            XCTAssertFalse(eventType.displayName.isEmpty, "Event type \(eventType.rawValue) should have a display name")
        }
        
        // Test specific display names
        XCTAssertEqual(WebhookEventType.invoicePaymentSucceeded.displayName, "Pagamento de Fatura Bem-sucedido")
        XCTAssertEqual(WebhookEventType.customerSubscriptionCreated.displayName, "Assinatura Criada")
        XCTAssertEqual(WebhookEventType.paymentIntentSucceeded.displayName, "Pagamento Bem-sucedido")
    }
}