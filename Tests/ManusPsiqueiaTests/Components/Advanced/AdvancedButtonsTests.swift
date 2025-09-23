import XCTest
import SwiftUI
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class AdvancedButtonsTests: XCTestCase {

    func testAdvancedButtonInitialization() {
        // Similar to AdvancedScrollView, direct unit testing of SwiftUI Views
        // is best done with SwiftUI Test or Snapshot Testing.
        // Here, we ensure basic initialization without crashing.
        
        let button = AdvancedButton(title: "Test Button") { /* action */ }
        XCTAssertNotNil(button, "AdvancedButton should be initializable")
    }
    
    func testAdvancedPrimaryButtonInitialization() {
        let button = AdvancedPrimaryButton(title: "Primary Button") { /* action */ }
        XCTAssertNotNil(button, "AdvancedPrimaryButton should be initializable")
    }
    
    func testAdvancedSecondaryButtonInitialization() {
        let button = AdvancedSecondaryButton(title: "Secondary Button") { /* action */ }
        XCTAssertNotNil(button, "AdvancedSecondaryButton should be initializable")
    }
}


