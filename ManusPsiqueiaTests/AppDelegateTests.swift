//
//  AppDelegateTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia
import StripePaymentSheet

class AppDelegateTests: XCTestCase {
    
    func testAppDelegateExistsAndImplementsCorrectMethods() {
        // Test that AppDelegate exists and has the required method
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
        
        // Test the method signature exists
        let application = UIApplication.shared
        let result = appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        XCTAssertTrue(result, "didFinishLaunchingWithOptions should return true")
    }
    
    func testStripeKeyIsSetInAppDelegate() {
        // Test that when AppDelegate method is called, it sets the Stripe key
        let appDelegate = AppDelegate()
        let application = UIApplication.shared
        
        // Call the method that should set the Stripe key
        _ = appDelegate.application(application, didFinishLaunchingWithOptions: nil)
        
        // Verify the Stripe key is set to the expected value
        let expectedKey = "pk_test_51S8PNiKTemOlkuQhCDfEcMAmPRnLb0ly5HRiKxEfsMjmxMJOwWtW1l1sJCyo8DCTsCTuQDXTHiqvUnzBajD1F3PI007O04DVsY"
        XCTAssertEqual(StripeAPI.defaultPublishableKey, expectedKey, "Stripe API key should be set to the expected value")
    }
}