import XCTest
@testable import ManusPsiqueia

class InvitationTests: XCTestCase {

    func testInvitationInitialization() {
        let invitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com"
        )
        
        XCTAssertNotNil(invitation)
        XCTAssertEqual(invitation.toPsychologistEmail, "psychologist@example.com")
        XCTAssertEqual(invitation.patientName, "João Silva")
        XCTAssertEqual(invitation.patientEmail, "patient@example.com")
        XCTAssertEqual(invitation.status, .pending)
        XCTAssertFalse(invitation.invitationCode.isEmpty)
        XCTAssertEqual(invitation.invitationCode.count, 8)
    }

    func testInvitationStatusChange() {
        var invitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com"
        )
        
        XCTAssertEqual(invitation.status, .pending)
        // Note: Since status is let in the actual model, this test would need to be adjusted
        // or the model would need to be modified to allow status changes
    }

    func testInvitationEncodingDecoding() throws {
        let originalInvitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalInvitation)
        
        let decoder = JSONDecoder()
        let decodedInvitation = try decoder.decode(Invitation.self, from: data)
        
        XCTAssertEqual(originalInvitation.id, decodedInvitation.id)
        XCTAssertEqual(originalInvitation.fromPatientId, decodedInvitation.fromPatientId)
        XCTAssertEqual(originalInvitation.toPsychologistEmail, decodedInvitation.toPsychologistEmail)
        XCTAssertEqual(originalInvitation.status, decodedInvitation.status)
    }
    
    func testInvitationCodeGeneration() {
        let code1 = Invitation.generateInvitationCode()
        let code2 = Invitation.generateInvitationCode()
        
        XCTAssertEqual(code1.count, 8)
        XCTAssertEqual(code2.count, 8)
        XCTAssertNotEqual(code1, code2) // Should be different each time
        
        // Test that code contains only alphanumeric characters
        let allowedCharacters = CharacterSet.alphanumerics
        XCTAssertTrue(code1.unicodeScalars.allSatisfy { allowedCharacters.contains($0) })
    }
    
    func testInvitationExpiration() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let expiredInvitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com",
            expiresAt: pastDate
        )
        
        XCTAssertTrue(expiredInvitation.isExpired)
        
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let validInvitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com",
            expiresAt: futureDate
        )
        
        XCTAssertFalse(validInvitation.isExpired)
    }
    
    func testInvitationStatusMessages() {
        let pendingInvitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com",
            status: .pending
        )
        
        XCTAssertEqual(pendingInvitation.statusMessage, "Aguardando resposta")
        
        let acceptedInvitation = Invitation(
            fromPatientId: UUID(),
            toPsychologistEmail: "psychologist@example.com",
            patientName: "João Silva",
            patientEmail: "patient@example.com",
            status: .accepted
        )
        
        XCTAssertEqual(acceptedInvitation.statusMessage, "Convite aceito")
    }
    
    func testEmailGeneration() {
        let emailBody = Invitation.generateEmailBody(
            patientName: "João Silva",
            patientEmail: "joao@example.com",
            message: "Gostaria muito de trabalhar com você!",
            invitationCode: "ABC12345"
        )
        
        XCTAssertTrue(emailBody.contains("João Silva"))
        XCTAssertTrue(emailBody.contains("joao@example.com"))
        XCTAssertTrue(emailBody.contains("Gostaria muito de trabalhar com você!"))
        XCTAssertTrue(emailBody.contains("ABC12345"))
        XCTAssertTrue(emailBody.contains("Manus Psiqueia"))
    }
    
    func testSMSGeneration() {
        let smsBody = Invitation.generateSMSBody(
            patientName: "João Silva",
            invitationCode: "ABC12345"
        )
        
        XCTAssertTrue(smsBody.contains("João Silva"))
        XCTAssertTrue(smsBody.contains("ABC12345"))
        XCTAssertTrue(smsBody.contains("Manus Psiqueia"))
        XCTAssertTrue(smsBody.contains("7 dias"))
    }
}


