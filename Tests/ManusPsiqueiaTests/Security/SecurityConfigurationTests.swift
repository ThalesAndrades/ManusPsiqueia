import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class SecurityConfigurationTests: XCTestCase {

    func testDefaultConfigurationValues() {
        let config = SecurityConfiguration.default
        XCTAssertTrue(config.isCertificatePinningEnabled)
        XCTAssertTrue(config.isBiometricAuthenticationEnabled)
        XCTAssertEqual(config.minPasscodeLength, 6)
        XCTAssertEqual(config.sessionTimeoutInMinutes, 15)
    }

    func testCustomConfigurationValues() {
        let customConfig = SecurityConfiguration(
            isCertificatePinningEnabled: false,
            isBiometricAuthenticationEnabled: false,
            minPasscodeLength: 4,
            sessionTimeoutInMinutes: 30
        )
        XCTAssertFalse(customConfig.isCertificatePinningEnabled)
        XCTAssertFalse(customConfig.isBiometricAuthenticationEnabled)
        XCTAssertEqual(customConfig.minPasscodeLength, 4)
        XCTAssertEqual(customConfig.sessionTimeoutInMinutes, 30)
    }

    func testConfigurationEncodingDecoding() throws {
        let originalConfig = SecurityConfiguration.default
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalConfig)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(SecurityConfiguration.self, from: data)
        
        XCTAssertEqual(originalConfig.isCertificatePinningEnabled, decodedConfig.isCertificatePinningEnabled)
        XCTAssertEqual(originalConfig.isBiometricAuthenticationEnabled, decodedConfig.isBiometricAuthenticationEnabled)
        XCTAssertEqual(originalConfig.minPasscodeLength, decodedConfig.minPasscodeLength)
        XCTAssertEqual(originalConfig.sessionTimeoutInMinutes, decodedConfig.sessionTimeoutInMinutes)
    }
}


