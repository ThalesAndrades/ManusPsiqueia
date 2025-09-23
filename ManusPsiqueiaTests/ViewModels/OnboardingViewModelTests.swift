//
//  OnboardingViewModelTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
import SwiftUI
@testable import ManusPsiqueia

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUpWithError() throws {
        super.setUpWithError()
        viewModel = OnboardingViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        super.tearDownWithError()
    }
    
    func testInitialState() throws {
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertFalse(viewModel.showUserTypeSelection)
        XCTAssertFalse(viewModel.animateGradient)
        XCTAssertEqual(viewModel.particleOffset, 0)
        XCTAssertNil(viewModel.error)
    }
    
    func testNextPage() throws {
        viewModel.nextPage()
        XCTAssertEqual(viewModel.currentPage, 1)
    }
    
    func testNextPageAtLastPage() throws {
        // Go to last page
        while !viewModel.isLastPage {
            viewModel.nextPage()
        }
        let lastPage = viewModel.currentPage
        
        // Try to go beyond last page
        viewModel.nextPage()
        XCTAssertEqual(viewModel.currentPage, lastPage)
    }
    
    func testShowUserSelection() throws {
        XCTAssertFalse(viewModel.showUserTypeSelection)
        viewModel.showUserSelection()
        XCTAssertTrue(viewModel.showUserTypeSelection)
    }
    
    func testHideUserSelection() throws {
        viewModel.showUserSelection()
        XCTAssertTrue(viewModel.showUserTypeSelection)
        
        viewModel.hideUserSelection()
        XCTAssertFalse(viewModel.showUserTypeSelection)
    }
    
    func testIsLastPage() throws {
        XCTAssertFalse(viewModel.isLastPage)
        
        // Navigate to last page
        while !viewModel.isLastPage {
            viewModel.nextPage()
        }
        
        XCTAssertTrue(viewModel.isLastPage)
    }
    
    func testShouldShowSkipButton() throws {
        XCTAssertTrue(viewModel.shouldShowSkipButton)
        
        // Navigate to last page
        while !viewModel.isLastPage {
            viewModel.nextPage()
        }
        
        XCTAssertFalse(viewModel.shouldShowSkipButton)
    }
    
    func testStartAnimations() throws {
        XCTAssertFalse(viewModel.animateGradient)
        
        viewModel.startAnimations()
        
        // Animation should start
        XCTAssertTrue(viewModel.animateGradient)
    }
    
    func testErrorHandling() throws {
        let testError = NetworkError.noInternetConnection
        let identifiableError = IdentifiableError(error: testError)
        
        viewModel.error = identifiableError
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error?.localizedDescription, testError.localizedDescription)
        
        viewModel.clearError()
        XCTAssertNil(viewModel.error)
    }
}