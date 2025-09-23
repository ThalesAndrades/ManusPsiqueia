import XCTest
import SwiftUI
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class ParticlesViewTests: XCTestCase {

    func testParticlesViewInitialization() {
        // Similar to other SwiftUI Views, direct unit testing of its UI behavior
        // is best done with SwiftUI Test or Snapshot Testing.
        // Here, we ensure basic initialization without crashing.
        
        let view = ParticlesView()
        XCTAssertNotNil(view, "ParticlesView should be initializable")
    }
}


