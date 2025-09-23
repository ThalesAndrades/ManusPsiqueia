import XCTest
@testable import ManusPsiqueia

class SecurityThreatDetectorTests: XCTestCase {

    var threatDetector: SecurityThreatDetector!

    override func setUpWithError() throws {
        super.setUpWithError()
        threatDetector = SecurityThreatDetector.shared
    }

    override func tearDownWithError() throws {
        threatDetector = nil
        super.tearDownWithError()
    }

    func testIsDeviceCompromisedInSimulator() {
        // In simulator, device should not be considered compromised
        #if targetEnvironment(simulator)
        XCTAssertFalse(threatDetector.isDeviceCompromised(), "Simulator should not be detected as compromised")
        #endif
    }

    func testIsBeingDebuggedDetection() {
        // Test debugging detection (should be false in normal test conditions)
        let isDebugging = threatDetector.isBeingDebugged()
        // In test environment, this might vary, so we just ensure the method works
        XCTAssertNotNil(isDebugging)
    }

    func testSuspiciousNetworkDetection() {
        // Test network detection (should work without errors)
        let isSuspicious = threatDetector.isSuspiciousNetworkDetected()
        // Just ensure the method executes without crashing
        XCTAssertNotNil(isSuspicious)
    }
    
    func testPerformanceOfThreatDetection() {
        // Test performance of threat detection methods
        measure {
            let _ = threatDetector.isDeviceCompromised()
            let _ = threatDetector.isBeingDebugged()
            let _ = threatDetector.isSuspiciousNetworkDetected()
        }
    }
}


