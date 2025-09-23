import XCTest
@testable import ManusPsiqueia

class InvitationTests: XCTestCase {

    func testInvitationInitialization() {
        let invitation = Invitation(id: "inv_123", senderId: "psy_456", receiverEmail: "patient@example.com", status: .pending, sentDate: Date())
        XCTAssertNotNil(invitation)
        XCTAssertEqual(invitation.id, "inv_123")
        XCTAssertEqual(invitation.senderId, "psy_456")
        XCTAssertEqual(invitation.receiverEmail, "patient@example.com")
        XCTAssertEqual(invitation.status, .pending)
    }

    func testInvitationStatusChange() {
        var invitation = Invitation(id: "inv_123", senderId: "psy_456", receiverEmail: "patient@example.com", status: .pending, sentDate: Date())
        XCTAssertEqual(invitation.status, .pending)
        invitation.status = .accepted
        XCTAssertEqual(invitation.status, .accepted)
    }

    func testInvitationEncodingDecoding() throws {
        let originalInvitation = Invitation(id: "inv_123", senderId: "psy_456", receiverEmail: "patient@example.com", status: .pending, sentDate: Date())
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalInvitation)
        
        let decoder = JSONDecoder()
        let decodedInvitation = try decoder.decode(Invitation.self, from: data)
        
        XCTAssertEqual(originalInvitation.id, decodedInvitation.id)
        XCTAssertEqual(originalInvitation.senderId, decodedInvitation.senderId)
        XCTAssertEqual(originalInvitation.receiverEmail, decodedInvitation.receiverEmail)
        XCTAssertEqual(originalInvitation.status, decodedInvitation.status)
    }
}


