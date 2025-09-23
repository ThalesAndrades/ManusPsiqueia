import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class DiarySecurityManagerTests: XCTestCase {

    var diarySecurityManager: DiarySecurityManager!
    var mockKeychainManager: MockKeychainManager!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockKeychainManager = MockKeychainManager()
        diarySecurityManager = DiarySecurityManager(keychainManager: mockKeychainManager)
    }

    override func tearDownWithError() throws {
        diarySecurityManager = nil
        mockKeychainManager = nil
        super.tearDownWithError()
    }

    func testSetAndVerifyPasscode_success() throws {
        let passcode = "1234"
        XCTAssertTrue(diarySecurityManager.setPasscode(passcode))
        XCTAssertTrue(diarySecurityManager.verifyPasscode(passcode))
    }

    func testSetAndVerifyPasscode_failure() throws {
        let passcode = "1234"
        let wrongPasscode = "4321"
        XCTAssertTrue(diarySecurityManager.setPasscode(passcode))
        XCTAssertFalse(diarySecurityManager.verifyPasscode(wrongPasscode))
    }

    func testRemovePasscode() throws {
        let passcode = "1234"
        XCTAssertTrue(diarySecurityManager.setPasscode(passcode))
        XCTAssertTrue(diarySecurityManager.removePasscode())
        XCTAssertFalse(diarySecurityManager.verifyPasscode(passcode)) // Should fail after removal
    }

    func testIsPasscodeSet() throws {
        XCTAssertFalse(diarySecurityManager.isPasscodeSet())
        _ = diarySecurityManager.setPasscode("1234")
        XCTAssertTrue(diarySecurityManager.isPasscodeSet())
        _ = diarySecurityManager.removePasscode()
        XCTAssertFalse(diarySecurityManager.isPasscodeSet())
    }
}

// Mock KeychainManager for testing DiarySecurityManager
class MockKeychainManager: KeychainManagerProtocol {
    var storedPasscode: String? = nil

    func save(key: String, data: String) -> Bool {
        if key == "diaryPasscode" {
            storedPasscode = data
            return true
        }
        return false
    }

    func load(key: String) -> String? {
        if key == "diaryPasscode" {
            return storedPasscode
        }
        return nil
    }

    func delete(key: String) -> Bool {
        if key == "diaryPasscode" {
            storedPasscode = nil
            return true
        }
        return false
    }
}


