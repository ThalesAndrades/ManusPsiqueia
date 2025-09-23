import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

class SecurityThreatDetectorTests: XCTestCase {

    var threatDetector: SecurityThreatDetector!
    var mockAuditLogger: MockAuditLogger!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockAuditLogger = MockAuditLogger()
        threatDetector = SecurityThreatDetector(auditLogger: mockAuditLogger)
    }

    override func tearDownWithError() throws {
        threatDetector = nil
        mockAuditLogger = nil
        super.tearDownWithError()
    }

    func testDetectUnusualLoginAttempts() {
        // Simulate multiple failed login attempts from the same IP
        threatDetector.recordLoginAttempt(userId: "user_1", success: false, ipAddress: "192.168.1.1")
        threatDetector.recordLoginAttempt(userId: "user_1", success: false, ipAddress: "192.168.1.1")
        threatDetector.recordLoginAttempt(userId: "user_1", success: false, ipAddress: "192.168.1.1")
        
        // This should trigger a threat detection and log an incident
        XCTAssertTrue(mockAuditLogger.loggedEvents.contains(where: { $0.contains("Potencial ameaça de segurança detectada: Múltiplas tentativas de login falhas") }))
    }

    func testDetectDataTamperingAttempt() {
        // Simulate a data tampering attempt
        threatDetector.recordDataModification(userId: "user_2", dataIdentifier: "diary_entry_1", success: false)
        
        // This should trigger a threat detection and log an incident
        XCTAssertTrue(mockAuditLogger.loggedEvents.contains(where: { $0.contains("Potencial ameaça de segurança detectada: Tentativa de adulteração de dados") }))
    }

    func testNoThreatDetectedForSuccessfulLogin() {
        let initialLogCount = mockAuditLogger.loggedEvents.count
        threatDetector.recordLoginAttempt(userId: "user_3", success: true, ipAddress: "192.168.1.2")
        XCTAssertEqual(mockAuditLogger.loggedEvents.count, initialLogCount)
    }
}

// Mock AuditLogger for testing SecurityThreatDetector
class MockAuditLogger: AuditLoggerProtocol {
    var loggedEvents: [String] = []

    func logEvent(_ event: String) {
        loggedEvents.append(event)
    }

    func logSensitiveEvent(_ event: String, userId: String) {
        loggedEvents.append("Sensitive: \(event) for user \(userId)")
    }

    func getRecentLogs(count: Int) -> [String] {
        return Array(loggedEvents.suffix(count))
    }
}


