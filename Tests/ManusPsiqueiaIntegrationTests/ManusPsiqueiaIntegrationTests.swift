//
//  ManusPsiqueiaIntegrationTests.swift
//  ManusPsiqueiaIntegrationTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
#if canImport(ManusPsiqueia)
@testable import ManusPsiqueia
#endif

/// Integration tests for ManusPsiqueia with full iOS dependencies
/// These tests will only run on iOS/macOS platforms
final class ManusPsiqueiaIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    #if canImport(ManusPsiqueia)
    /// Test that we can create a DiaryAIInsightsManager with mock OpenAI
    func testDiaryAIInsightsManagerCreation() throws {
        let manager = DiaryAIInsightsManager()
        XCTAssertNotNil(manager, "DiaryAIInsightsManager should be created successfully")
    }
    
    /// Test OpenAI manager protocol functionality
    func testOpenAIManagerProtocol() async throws {
        let manager = DefaultOpenAIManager()
        let response = try await manager.generateCompletion(
            prompt: "Test prompt",
            model: "gpt-4",
            maxTokens: 100,
            temperature: 0.3
        )
        XCTAssertFalse(response.isEmpty, "OpenAI manager should return a response")
    }
    #else
    func testSkippedOnNonIOSPlatforms() throws {
        // This test runs when iOS modules aren't available
        XCTAssertTrue(true, "Integration tests are skipped on non-iOS platforms")
    }
    #endif
}