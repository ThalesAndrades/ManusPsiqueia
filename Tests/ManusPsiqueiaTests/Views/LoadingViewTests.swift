import XCTest
import SwiftUI
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class LoadingViewTests: XCTestCase {

    func testLoadingViewInitialization() {
        // Similar to other SwiftUI Views, direct unit testing of its UI behavior
        // is best done with SwiftUI Test or Snapshot Testing.
        // Here, we ensure basic initialization without crashing.
        
        let view = LoadingView()
        XCTAssertNotNil(view, "LoadingView should be initializable")
    }
}


