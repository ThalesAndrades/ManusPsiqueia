import XCTest
@testable import ManusPsiqueia

class SecurityIncidentManagerTests: XCTestCase {

    var securityIncidentManager: SecurityIncidentManager!
    var mockIncidentStorage: MockIncidentStorage!

    override func setUpWithError() throws {
        super.setUpWithError()
        mockIncidentStorage = MockIncidentStorage()
        securityIncidentManager = SecurityIncidentManager(incidentStorage: mockIncidentStorage)
    }

    override func tearDownWithError() throws {
        securityIncidentManager = nil
        mockIncidentStorage = nil
        super.tearDownWithError()
    }

    func testReportIncident() {
        let incidentType = "Unauthorized Access"
        let description = "Attempted login with invalid credentials."
        let userId = "user_123"
        
        securityIncidentManager.reportIncident(type: incidentType, description: description, userId: userId)
        
        XCTAssertEqual(mockIncidentStorage.reportedIncidents.count, 1)
        let reportedIncident = mockIncidentStorage.reportedIncidents.first
        XCTAssertEqual(reportedIncident?.type, incidentType)
        XCTAssertEqual(reportedIncident?.description, description)
        XCTAssertEqual(reportedIncident?.userId, userId)
        XCTAssertNotNil(reportedIncident?.date)
    }

    func testGetRecentIncidents() {
        securityIncidentManager.reportIncident(type: "Type A", description: "Desc A", userId: "user_A")
        securityIncidentManager.reportIncident(type: "Type B", description: "Desc B", userId: "user_B")
        securityIncidentManager.reportIncident(type: "Type C", description: "Desc C", userId: "user_C")

        let recentIncidents = securityIncidentManager.getRecentIncidents(count: 2)
        XCTAssertEqual(recentIncidents.count, 2)
        XCTAssertTrue(recentIncidents.contains(where: { $0.type == "Type C" }))
        XCTAssertTrue(recentIncidents.contains(where: { $0.type == "Type B" }))
        XCTAssertFalse(recentIncidents.contains(where: { $0.type == "Type A" }))
    }
}

// Mock IncidentStorage for testing SecurityIncidentManager
class MockIncidentStorage: IncidentStorageProtocol {
    var reportedIncidents: [SecurityIncident] = []

    func saveIncident(_ incident: SecurityIncident) {
        reportedIncidents.append(incident)
    }

    func fetchIncidents(count: Int) -> [SecurityIncident] {
        return Array(reportedIncidents.suffix(count))
    }
}


