//
//  FlowManagerTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
import SwiftUI
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

@MainActor
class FlowManagerTests: XCTestCase {
    var flowManager: FlowManager!
    
    override func setUp() {
        super.setUp()
        flowManager = FlowManager.shared
        
        // Reset flow manager state before each test
        flowManager.currentFlow = nil
        flowManager.flowState = .idle
        flowManager.showPaywall = false
        flowManager.showOnboarding = false
        flowManager.pendingDeepLink = nil
        flowManager.navigationPath = NavigationPath()
    }
    
    override func tearDown() {
        flowManager = nil
        super.tearDown()
    }
    
    // MARK: - Flow Control Tests
    
    func testStartFlow() {
        // Given
        let expectedFlow = AppFlow.diary
        let metadata = ["test": "value"]
        
        // When
        flowManager.startFlow(expectedFlow, metadata: metadata)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, expectedFlow)
        XCTAssertEqual(flowManager.flowState, .inProgress)
    }
    
    func testCompleteFlow() {
        // Given
        flowManager.startFlow(.diary)
        
        // When
        flowManager.completeFlow()
        
        // Then
        XCTAssertEqual(flowManager.flowState, .completed)
        
        // Wait for the delayed reset
        let expectation = XCTestExpectation(description: "Flow reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertNil(self.flowManager.currentFlow)
            XCTAssertEqual(self.flowManager.flowState, .idle)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testFailFlow() {
        // Given
        let testError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        flowManager.startFlow(.subscription)
        
        // When
        flowManager.failFlow(error: testError)
        
        // Then
        if case .failed(let error) = flowManager.flowState {
            XCTAssertEqual(error.localizedDescription, testError.localizedDescription)
        } else {
            XCTFail("Flow state should be failed")
        }
    }
    
    // MARK: - Deep Link Tests
    
    func testHandleValidDeepLink() {
        // Given
        let url = URL(string: "manuspsiqueia://diary/new")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .diary)
    }
    
    func testHandleInvalidSchemeDeepLink() {
        // Given
        let url = URL(string: "invalid://diary/new")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertNil(flowManager.currentFlow)
    }
    
    func testHandleDiaryNewEntryDeepLink() {
        // Given
        let url = URL(string: "manuspsiqueia://diary/new")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .diary)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .diary)
        let lastEvent = events.last
        XCTAssertEqual(lastEvent?.action, "started")
        XCTAssertEqual(lastEvent?.metadata["action"] as? String, "new_entry")
        XCTAssertEqual(lastEvent?.metadata["source"] as? String, "deep_link")
    }
    
    func testHandleDiaryViewEntryDeepLink() {
        // Given
        let entryId = "test-entry-123"
        let url = URL(string: "manuspsiqueia://diary/entry/\(entryId)")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .diary)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .diary)
        let lastEvent = events.last
        XCTAssertEqual(lastEvent?.action, "started")
        XCTAssertEqual(lastEvent?.metadata["action"] as? String, "view_entry")
        XCTAssertEqual(lastEvent?.metadata["entry_id"] as? String, entryId)
        XCTAssertEqual(lastEvent?.metadata["source"] as? String, "deep_link")
    }
    
    func testHandleGoalsNewDeepLink() {
        // Given
        let url = URL(string: "manuspsiqueia://goals/new")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .goals)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .goals)
        let lastEvent = events.last
        XCTAssertEqual(lastEvent?.action, "started")
        XCTAssertEqual(lastEvent?.metadata["action"] as? String, "new_goal")
    }
    
    func testHandleSubscriptionDeepLink() {
        // Given
        let url = URL(string: "manuspsiqueia://subscription")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .paywall)
        XCTAssertTrue(flowManager.showPaywall)
    }
    
    func testHandleSettingsDeepLink() {
        // Given
        let section = "privacy"
        let url = URL(string: "manuspsiqueia://settings/\(section)")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .settings)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .settings)
        let lastEvent = events.last
        XCTAssertEqual(lastEvent?.action, "started")
        XCTAssertEqual(lastEvent?.metadata["section"] as? String, section)
        XCTAssertEqual(lastEvent?.metadata["source"] as? String, "deep_link")
    }
    
    func testHandleUnknownDeepLink() {
        // Given
        let url = URL(string: "manuspsiqueia://unknown/path")!
        
        // When
        flowManager.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(flowManager.pendingDeepLink, url)
        XCTAssertNil(flowManager.currentFlow)
    }
    
    // MARK: - Flow Analytics Tests
    
    func testFlowEventTracking() {
        // Given
        let flow = AppFlow.insights
        let metadata = ["user_id": "123", "source": "test"]
        
        // When
        flowManager.startFlow(flow, metadata: metadata)
        flowManager.completeFlow()
        
        // Then
        let events = flowManager.getFlowEvents(for: flow)
        XCTAssertEqual(events.count, 2)
        
        let startEvent = events.first
        XCTAssertEqual(startEvent?.flowType, flow)
        XCTAssertEqual(startEvent?.action, "started")
        XCTAssertEqual(startEvent?.metadata["user_id"] as? String, "123")
        
        let completeEvent = events.last
        XCTAssertEqual(completeEvent?.flowType, flow)
        XCTAssertEqual(completeEvent?.action, "completed")
    }
    
    func testFlowCompletionRate() {
        // Given
        let flow = AppFlow.profile
        
        // When - start multiple flows, complete some
        flowManager.startFlow(flow)
        flowManager.completeFlow()
        
        flowManager.startFlow(flow)
        flowManager.completeFlow()
        
        flowManager.startFlow(flow)
        flowManager.failFlow(error: NSError(domain: "test", code: 1))
        
        // Then
        let completionRate = flowManager.getFlowCompletionRate(for: flow)
        XCTAssertEqual(completionRate, 2.0/3.0, accuracy: 0.01)
    }
    
    func testGetAllFlowEvents() {
        // Given
        flowManager.startFlow(.diary)
        flowManager.completeFlow()
        
        flowManager.startFlow(.insights)
        flowManager.completeFlow()
        
        // When
        let allEvents = flowManager.getFlowEvents()
        
        // Then
        XCTAssertEqual(allEvents.count, 4) // 2 start + 2 complete events
        
        let diaryEvents = allEvents.filter { $0.flowType == .diary }
        let insightsEvents = allEvents.filter { $0.flowType == .insights }
        
        XCTAssertEqual(diaryEvents.count, 2)
        XCTAssertEqual(insightsEvents.count, 2)
    }
    
    // MARK: - Flow Recovery Tests
    
    func testRecoverFromFailedFlow() {
        // Given
        flowManager.startFlow(.subscription)
        let testError = NSError(domain: "TestError", code: 1)
        flowManager.failFlow(error: testError)
        flowManager.showPaywall = true
        flowManager.showOnboarding = true
        
        // When
        flowManager.recoverFromFailedFlow()
        
        // Then
        XCTAssertNil(flowManager.currentFlow)
        XCTAssertEqual(flowManager.flowState, .idle)
        XCTAssertFalse(flowManager.showPaywall)
        XCTAssertFalse(flowManager.showOnboarding)
        XCTAssertEqual(flowManager.navigationPath.count, 0)
    }
    
    // MARK: - Flow State Management Tests
    
    func testOnboardingFlow() {
        // When
        flowManager.startFlow(.onboarding)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .onboarding)
        XCTAssertTrue(flowManager.showOnboarding)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .onboarding)
        let initEvent = events.first { $0.action == "initialized" }
        XCTAssertNotNil(initEvent)
        XCTAssertNotNil(initEvent?.metadata["first_time"])
    }
    
    func testPaywallFlow() {
        // When
        flowManager.startFlow(.paywall)
        
        // Then
        XCTAssertEqual(flowManager.currentFlow, .paywall)
        XCTAssertTrue(flowManager.showPaywall)
        
        // Check that the correct flow event was tracked
        let events = flowManager.getFlowEvents(for: .paywall)
        let presentedEvent = events.first { $0.action == "presented" }
        XCTAssertNotNil(presentedEvent)
        XCTAssertEqual(presentedEvent?.metadata["trigger"] as? String, "manual")
    }
    
    // MARK: - Performance Tests
    
    func testFlowEventMemoryManagement() {
        // Given - create more than 100 events
        for i in 0..<150 {
            flowManager.startFlow(.diary, metadata: ["iteration": i])
            flowManager.completeFlow()
        }
        
        // When
        let allEvents = flowManager.getFlowEvents()
        
        // Then - should not exceed 100 events
        XCTAssertLessThanOrEqual(allEvents.count, 100)
    }
}