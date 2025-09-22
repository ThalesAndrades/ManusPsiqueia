//
//  SubscriptionServiceTests.swift
//  ManusPsiqueiaTests
//
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 ManusPsiqueia. All rights reserved.
//

import XCTest
import Stripe
@testable import ManusPsiqueia

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    
    var subscriptionService: SubscriptionService!
    var mockStripeManager: MockStripeManager!
    var mockNetworkManager: MockNetworkManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockStripeManager = MockStripeManager()
        mockNetworkManager = MockNetworkManager()
        subscriptionService = SubscriptionService(
            stripeManager: mockStripeManager,
            networkManager: mockNetworkManager
        )
    }
    
    override func tearDown() async throws {
        subscriptionService = nil
        mockStripeManager = nil
        mockNetworkManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Subscription Creation Tests
    
    func testCreateSubscription_Success() async throws {
        // Given
        let psychologistId = "psych_123"
        let planId = "plan_premium"
        let expectedSubscription = Subscription(
            id: "sub_123",
            userId: psychologistId,
            planId: planId,
            status: .active,
            currentPeriodStart: Date(),
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            amount: 89.90,
            currency: "BRL"
        )
        
        mockStripeManager.mockSubscription = expectedSubscription
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.createSubscription(
            for: psychologistId,
            planId: planId
        )
        
        // Then
        switch result {
        case .success(let subscription):
            XCTAssertEqual(subscription.userId, psychologistId)
            XCTAssertEqual(subscription.planId, planId)
            XCTAssertEqual(subscription.status, .active)
            XCTAssertEqual(subscription.amount, 89.90)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    func testCreateSubscription_StripeError() async throws {
        // Given
        let psychologistId = "psych_123"
        let planId = "plan_premium"
        
        mockStripeManager.shouldSucceed = false
        mockStripeManager.mockError = StripeError.cardDeclined
        
        // When
        let result = await subscriptionService.createSubscription(
            for: psychologistId,
            planId: planId
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to Stripe error")
        case .failure(let error):
            XCTAssertTrue(error is StripeError)
        }
    }
    
    // MARK: - Subscription Status Tests
    
    func testGetSubscriptionStatus_Active() async throws {
        // Given
        let psychologistId = "psych_123"
        let activeSubscription = Subscription(
            id: "sub_123",
            userId: psychologistId,
            planId: "plan_premium",
            status: .active,
            currentPeriodStart: Date(),
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            amount: 89.90,
            currency: "BRL"
        )
        
        mockNetworkManager.mockSubscription = activeSubscription
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.getSubscriptionStatus(for: psychologistId)
        
        // Then
        switch result {
        case .success(let subscription):
            XCTAssertEqual(subscription.status, .active)
            XCTAssertEqual(subscription.userId, psychologistId)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    func testGetSubscriptionStatus_Expired() async throws {
        // Given
        let psychologistId = "psych_123"
        let expiredSubscription = Subscription(
            id: "sub_123",
            userId: psychologistId,
            planId: "plan_premium",
            status: .expired,
            currentPeriodStart: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            amount: 89.90,
            currency: "BRL"
        )
        
        mockNetworkManager.mockSubscription = expiredSubscription
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.getSubscriptionStatus(for: psychologistId)
        
        // Then
        switch result {
        case .success(let subscription):
            XCTAssertEqual(subscription.status, .expired)
            XCTAssertTrue(subscription.isExpired)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Subscription Cancellation Tests
    
    func testCancelSubscription_Success() async throws {
        // Given
        let subscriptionId = "sub_123"
        let reason = "Não preciso mais do serviço"
        
        mockStripeManager.shouldSucceed = true
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.cancelSubscription(
            subscriptionId: subscriptionId,
            reason: reason
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockStripeManager.cancelSubscriptionCalled)
            XCTAssertTrue(mockNetworkManager.updateSubscriptionStatusCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    func testCancelSubscription_AlreadyCancelled() async throws {
        // Given
        let subscriptionId = "sub_123"
        let reason = "Teste"
        
        mockStripeManager.shouldSucceed = false
        mockStripeManager.mockError = StripeError.subscriptionAlreadyCancelled
        
        // When
        let result = await subscriptionService.cancelSubscription(
            subscriptionId: subscriptionId,
            reason: reason
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for already cancelled subscription")
        case .failure(let error):
            XCTAssertTrue(error is StripeError)
        }
    }
    
    // MARK: - Subscription Renewal Tests
    
    func testRenewSubscription_Success() async throws {
        // Given
        let subscriptionId = "sub_123"
        let newPlanId = "plan_premium_yearly"
        
        mockStripeManager.shouldSucceed = true
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.renewSubscription(
            subscriptionId: subscriptionId,
            newPlanId: newPlanId
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockStripeManager.updateSubscriptionCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Payment Method Tests
    
    func testUpdatePaymentMethod_Success() async throws {
        // Given
        let subscriptionId = "sub_123"
        let paymentMethodId = "pm_123"
        
        mockStripeManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.updatePaymentMethod(
            subscriptionId: subscriptionId,
            paymentMethodId: paymentMethodId
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockStripeManager.updatePaymentMethodCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Subscription Validation Tests
    
    func testValidateSubscription_Active() async throws {
        // Given
        let psychologistId = "psych_123"
        let activeSubscription = Subscription(
            id: "sub_123",
            userId: psychologistId,
            planId: "plan_premium",
            status: .active,
            currentPeriodStart: Date(),
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            amount: 89.90,
            currency: "BRL"
        )
        
        mockNetworkManager.mockSubscription = activeSubscription
        mockNetworkManager.shouldSucceed = true
        
        // When
        let isValid = await subscriptionService.validateSubscription(for: psychologistId)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateSubscription_Expired() async throws {
        // Given
        let psychologistId = "psych_123"
        let expiredSubscription = Subscription(
            id: "sub_123",
            userId: psychologistId,
            planId: "plan_premium",
            status: .expired,
            currentPeriodStart: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            currentPeriodEnd: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            amount: 89.90,
            currency: "BRL"
        )
        
        mockNetworkManager.mockSubscription = expiredSubscription
        mockNetworkManager.shouldSucceed = true
        
        // When
        let isValid = await subscriptionService.validateSubscription(for: psychologistId)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Billing History Tests
    
    func testGetBillingHistory_Success() async throws {
        // Given
        let psychologistId = "psych_123"
        let expectedInvoices = [
            Invoice(
                id: "inv_1",
                subscriptionId: "sub_123",
                amount: 89.90,
                currency: "BRL",
                status: .paid,
                createdAt: Date(),
                paidAt: Date()
            ),
            Invoice(
                id: "inv_2",
                subscriptionId: "sub_123",
                amount: 89.90,
                currency: "BRL",
                status: .paid,
                createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                paidAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            )
        ]
        
        mockStripeManager.mockInvoices = expectedInvoices
        mockStripeManager.shouldSucceed = true
        
        // When
        let result = await subscriptionService.getBillingHistory(for: psychologistId)
        
        // Then
        switch result {
        case .success(let invoices):
            XCTAssertEqual(invoices.count, 2)
            XCTAssertTrue(invoices.allSatisfy { $0.status == .paid })
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkError_Handling() async throws {
        // Given
        let psychologistId = "psych_123"
        mockNetworkManager.shouldSucceed = false
        mockNetworkManager.mockError = NetworkError.connectionFailed
        
        // When
        let result = await subscriptionService.getSubscriptionStatus(for: psychologistId)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to network error")
        case .failure(let error):
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Mock Classes

class MockStripeManager {
    var shouldSucceed = true
    var mockError: Error?
    var mockSubscription: Subscription?
    var mockInvoices: [Invoice] = []
    
    var cancelSubscriptionCalled = false
    var updateSubscriptionCalled = false
    var updatePaymentMethodCalled = false
    
    func createSubscription(for userId: String, planId: String) async -> Result<Subscription, Error> {
        if shouldSucceed, let subscription = mockSubscription {
            return .success(subscription)
        } else {
            return .failure(mockError ?? StripeError.unknown)
        }
    }
    
    func cancelSubscription(subscriptionId: String) async -> Result<Void, Error> {
        cancelSubscriptionCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? StripeError.unknown)
        }
    }
    
    func updateSubscription(subscriptionId: String, newPlanId: String) async -> Result<Void, Error> {
        updateSubscriptionCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? StripeError.unknown)
        }
    }
    
    func updatePaymentMethod(subscriptionId: String, paymentMethodId: String) async -> Result<Void, Error> {
        updatePaymentMethodCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? StripeError.unknown)
        }
    }
    
    func getBillingHistory(for userId: String) async -> Result<[Invoice], Error> {
        if shouldSucceed {
            return .success(mockInvoices)
        } else {
            return .failure(mockError ?? StripeError.unknown)
        }
    }
}

class MockNetworkManager {
    var shouldSucceed = true
    var mockError: Error?
    var mockSubscription: Subscription?
    
    var updateSubscriptionStatusCalled = false
    
    func getSubscription(for userId: String) async -> Result<Subscription, Error> {
        if shouldSucceed, let subscription = mockSubscription {
            return .success(subscription)
        } else {
            return .failure(mockError ?? NetworkError.notFound)
        }
    }
    
    func updateSubscriptionStatus(subscriptionId: String, status: SubscriptionStatus) async -> Result<Void, Error> {
        updateSubscriptionStatusCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? NetworkError.unknown)
        }
    }
}

// MARK: - Mock Models

struct Invoice: Codable {
    let id: String
    let subscriptionId: String
    let amount: Double
    let currency: String
    let status: InvoiceStatus
    let createdAt: Date
    let paidAt: Date?
}

enum InvoiceStatus: String, Codable {
    case paid = "paid"
    case pending = "pending"
    case failed = "failed"
}

enum StripeError: Error {
    case cardDeclined
    case subscriptionAlreadyCancelled
    case unknown
}

enum NetworkError: Error {
    case connectionFailed
    case notFound
    case unknown
}
