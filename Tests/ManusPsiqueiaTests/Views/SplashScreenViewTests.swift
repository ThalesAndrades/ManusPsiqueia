import XCTest
import SwiftUI
@testable import ManusPsiqueia

class SplashScreenViewTests: XCTestCase {

    func testSplashScreenViewInitialization() {
        // Similar to other SwiftUI Views, direct unit testing of its UI behavior
        // is best done with SwiftUI Test or Snapshot Testing.
        // Here, we ensure basic initialization without crashing.
        
        let view = SplashScreenView(isActive: .constant(true))
        XCTAssertNotNil(view, "SplashScreenView should be initializable")
    }
}


