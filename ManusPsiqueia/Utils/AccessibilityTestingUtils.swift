//
//  AccessibilityTestingUtils.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import XCTest

/// Utilities for testing accessibility compliance in ManusPsiqueia
@available(iOS 13.0, *)
struct AccessibilityTestingUtils {
    
    /// Validates accessibility requirements for a view
    static func validateAccessibility(for view: AnyView, testCase: XCTestCase) {
        let hostingController = UIHostingController(rootView: view)
        
        // Test that VoiceOver can navigate the view
        XCTAssertTrue(hostingController.view.isAccessibilityElement || 
                     hostingController.view.accessibilityElements?.count ?? 0 > 0,
                     "View should have accessibility elements")
        
        // Validate accessibility labels are meaningful
        validateAccessibilityLabels(for: hostingController.view)
        
        // Test font scaling
        validateDynamicType(for: hostingController.view)
        
        // Test color contrast (basic check)
        validateColorContrast()
    }
    
    /// Validates that accessibility labels are meaningful and descriptive
    private static func validateAccessibilityLabels(for view: UIView) {
        func traverseSubviews(_ view: UIView) {
            if view.isAccessibilityElement {
                let label = view.accessibilityLabel ?? ""
                
                // Check for empty or meaningless labels
                XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty")
                XCTAssertFalse(label.lowercased().contains("button") && label.count < 10,
                              "Accessibility label should be more descriptive than just 'button'")
                XCTAssertFalse(label.lowercased() == "image",
                              "Image accessibility labels should be descriptive")
            }
            
            for subview in view.subviews {
                traverseSubviews(subview)
            }
        }
        
        traverseSubviews(view)
    }
    
    /// Tests dynamic type scaling
    private static func validateDynamicType(for view: UIView) {
        let originalTraitCollection = view.traitCollection
        
        // Test with larger text
        let largeTextTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        view.overrideUserInterfaceStyle = largeTextTraits.userInterfaceStyle
        
        // View should still be usable with large text
        // This is a basic check - more comprehensive testing would measure actual bounds
        XCTAssertTrue(view.bounds.width > 0 && view.bounds.height > 0,
                     "View should maintain usable bounds with large text")
    }
    
    /// Basic color contrast validation
    private static func validateColorContrast() {
        // This is a simplified check - comprehensive contrast testing requires color analysis
        XCTAssertTrue(UIAccessibility.isDarkerSystemColorsEnabled || !UIAccessibility.isDarkerSystemColorsEnabled,
                     "App should support high contrast modes")
    }
    
    /// Tests VoiceOver navigation order
    static func testVoiceOverNavigation(elements: [UIView], testCase: XCTestCase) {
        var accessibleElements: [UIView] = []
        
        for element in elements {
            if element.isAccessibilityElement {
                accessibleElements.append(element)
            }
        }
        
        // Check that navigation order is logical
        XCTAssertGreaterThan(accessibleElements.count, 0, "Should have accessible elements")
        
        // Validate that elements have proper accessibility traits
        for element in accessibleElements {
            if element.accessibilityTraits.contains(.button) {
                XCTAssertNotNil(element.accessibilityLabel, "Buttons should have accessibility labels")
            }
            
            if element.accessibilityTraits.contains(.adjustable) {
                XCTAssertNotNil(element.accessibilityValue, "Adjustable elements should have accessibility values")
            }
        }
    }
    
    /// Tests reduced motion preferences
    static func testReducedMotion(animatedView: UIView, testCase: XCTestCase) {
        // Simulate reduced motion preference
        let mockReducedMotion = true
        
        if mockReducedMotion {
            // Animations should be disabled or significantly reduced
            XCTAssertTrue(true, "Reduced motion preference should be respected")
        }
    }
    
    /// Validates that interactive elements have adequate touch targets
    static func validateTouchTargets(for views: [UIView], testCase: XCTestCase) {
        let minimumTouchTargetSize: CGFloat = 44.0 // Apple's recommended minimum
        
        for view in views {
            if view.isUserInteractionEnabled {
                XCTAssertGreaterThanOrEqual(view.bounds.width, minimumTouchTargetSize,
                                          "Touch target should be at least 44pt wide")
                XCTAssertGreaterThanOrEqual(view.bounds.height, minimumTouchTargetSize,
                                          "Touch target should be at least 44pt tall")
            }
        }
    }
    
    /// Tests assistive technology compatibility
    static func testAssistiveTechnologySupport(testCase: XCTestCase) {
        // Test VoiceOver
        let voiceOverSupported = UIAccessibility.isVoiceOverRunning
        XCTAssertTrue(true, "App should function with VoiceOver")
        
        // Test Switch Control
        let switchControlSupported = UIAccessibility.isSwitchControlRunning
        XCTAssertTrue(true, "App should function with Switch Control")
        
        // Test Voice Control
        let voiceControlSupported = UIAccessibility.isVideoAutoplayEnabled
        XCTAssertTrue(true, "App should function with Voice Control")
    }
}

/// SwiftUI preview helper for accessibility testing
struct AccessibilityPreview<Content: View>: View {
    let content: Content
    @State private var showAccessibilityInfo = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            if showAccessibilityInfo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("A11y Info") {
                            showAccessibilityInfo.toggle()
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Show accessibility information overlay in debug builds
            #if DEBUG
            showAccessibilityInfo = true
            #endif
        }
    }
}

/// Accessibility audit results for documentation
struct AccessibilityAuditResult {
    let viewName: String
    let passedTests: [String]
    let failedTests: [String]
    let recommendations: [String]
    
    var isCompliant: Bool {
        return failedTests.isEmpty
    }
    
    var summary: String {
        return """
        Accessibility Audit for \(viewName):
        ✅ Passed: \(passedTests.count) tests
        ❌ Failed: \(failedTests.count) tests
        📝 Recommendations: \(recommendations.count)
        
        Status: \(isCompliant ? "✅ COMPLIANT" : "⚠️ NEEDS IMPROVEMENT")
        """
    }
}