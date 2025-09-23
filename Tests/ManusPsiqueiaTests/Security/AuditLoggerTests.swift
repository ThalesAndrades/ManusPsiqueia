import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class AuditLoggerTests: XCTestCase {

    var auditLogger: AuditLogger!
    var mockLogStorage: MockLogStorage!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockLogStorage = MockLogStorage()
        auditLogger = AuditLogger(logStorage: mockLogStorage)
    }

    override func tearDownWithError() throws {
        auditLogger = nil
        mockLogStorage = nil
        super.tearDownWithError()
    }

    func testLogEvent() {
        let event = "User logged in"
        auditLogger.logEvent(event)
        XCTAssertEqual(mockLogStorage.loggedEvents.count, 1)
        XCTAssertTrue(mockLogStorage.loggedEvents.first?.contains(event) ?? false)
    }

    func testLogSensitiveEvent() {
        let event = "Sensitive data accessed"
        let userId = "user_123"
        auditLogger.logSensitiveEvent(event, userId: userId)
        XCTAssertEqual(mockLogStorage.loggedEvents.count, 1)
        XCTAssertTrue(mockLogStorage.loggedEvents.first?.contains(event) ?? false)
        XCTAssertTrue(mockLogStorage.loggedEvents.first?.contains(userId) ?? false)
    }

    func testGetRecentLogs() {
        auditLogger.logEvent("Event 1")
        auditLogger.logEvent("Event 2")
        auditLogger.logEvent("Event 3")

        let recentLogs = auditLogger.getRecentLogs(count: 2)
        XCTAssertEqual(recentLogs.count, 2)
        XCTAssertTrue(recentLogs.contains(where: { $0.contains("Event 3") }))
        XCTAssertTrue(recentLogs.contains(where: { $0.contains("Event 2") }))
        XCTAssertFalse(recentLogs.contains(where: { $0.contains("Event 1") }))
    }
}

// Mock LogStorage for testing AuditLogger
class MockLogStorage: LogStorageProtocol {
    var loggedEvents: [String] = []

    func appendLog(_ logEntry: String) {
        loggedEvents.append(logEntry)
    }

    func getLogs(count: Int) -> [String] {
        return Array(loggedEvents.suffix(count))
    }
}


