//
//  InvitationManagerTests.swift
//  ManusPsiqueiaTests
//
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 ManusPsiqueia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

@MainActor
final class InvitationManagerTests: XCTestCase {
    
    var invitationManager: InvitationManager!
    var mockNetworkManager: MockNetworkManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockNetworkManager = MockNetworkManager()
        invitationManager = InvitationManager(networkManager: mockNetworkManager)
    }
    
    override func tearDown() async throws {
        invitationManager = nil
        mockNetworkManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Invitation Creation Tests
    
    func testCreateInvitation_Success() async throws {
        // Given
        let psychologistEmail = "psicologo@exemplo.com"
        let patientId = "patient_123"
        let expectedInvitation = Invitation(
            id: "inv_123",
            psychologistEmail: psychologistEmail,
            patientId: patientId,
            status: .pending,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        )
        
        mockNetworkManager.mockInvitation = expectedInvitation
        
        // When
        let result = await invitationManager.createInvitation(
            psychologistEmail: psychologistEmail,
            patientId: patientId
        )
        
        // Then
        switch result {
        case .success(let invitation):
            XCTAssertEqual(invitation.psychologistEmail, psychologistEmail)
            XCTAssertEqual(invitation.patientId, patientId)
            XCTAssertEqual(invitation.status, .pending)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    func testCreateInvitation_InvalidEmail() async throws {
        // Given
        let invalidEmail = "email-invalido"
        let patientId = "patient_123"
        
        // When
        let result = await invitationManager.createInvitation(
            psychologistEmail: invalidEmail,
            patientId: patientId
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for invalid email")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("email"))
        }
    }
    
    // MARK: - Invitation Status Tests
    
    func testAcceptInvitation_Success() async throws {
        // Given
        let invitationId = "inv_123"
        let psychologistId = "psych_456"
        
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await invitationManager.acceptInvitation(
            invitationId: invitationId,
            psychologistId: psychologistId
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockNetworkManager.acceptInvitationCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    func testRejectInvitation_Success() async throws {
        // Given
        let invitationId = "inv_123"
        let reason = "Não disponível no momento"
        
        mockNetworkManager.shouldSucceed = true
        
        // When
        let result = await invitationManager.rejectInvitation(
            invitationId: invitationId,
            reason: reason
        )
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(mockNetworkManager.rejectInvitationCalled)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Invitation Retrieval Tests
    
    func testGetPendingInvitations_Success() async throws {
        // Given
        let psychologistId = "psych_456"
        let expectedInvitations = [
            Invitation(
                id: "inv_1",
                psychologistEmail: "psicologo@exemplo.com",
                patientId: "patient_1",
                status: .pending,
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            ),
            Invitation(
                id: "inv_2",
                psychologistEmail: "psicologo@exemplo.com",
                patientId: "patient_2",
                status: .pending,
                createdAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            )
        ]
        
        mockNetworkManager.mockInvitations = expectedInvitations
        
        // When
        let result = await invitationManager.getPendingInvitations(for: psychologistId)
        
        // Then
        switch result {
        case .success(let invitations):
            XCTAssertEqual(invitations.count, 2)
            XCTAssertTrue(invitations.allSatisfy { $0.status == .pending })
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateEmail_ValidEmails() {
        let validEmails = [
            "test@exemplo.com",
            "usuario.teste@dominio.com.br",
            "psicologo123@clinica.org"
        ]
        
        for email in validEmails {
            XCTAssertTrue(
                invitationManager.isValidEmail(email),
                "Email \(email) deveria ser válido"
            )
        }
    }
    
    func testValidateEmail_InvalidEmails() {
        let invalidEmails = [
            "email-sem-arroba",
            "@dominio.com",
            "usuario@",
            "usuario@dominio",
            ""
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(
                invitationManager.isValidEmail(email),
                "Email \(email) deveria ser inválido"
            )
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkError_Handling() async throws {
        // Given
        mockNetworkManager.shouldSucceed = false
        mockNetworkManager.mockError = NetworkError.connectionFailed
        
        // When
        let result = await invitationManager.createInvitation(
            psychologistEmail: "test@exemplo.com",
            patientId: "patient_123"
        )
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure due to network error")
        case .failure(let error):
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Mock Classes

class MockNetworkManager {
    var shouldSucceed = true
    var mockError: Error?
    var mockInvitation: Invitation?
    var mockInvitations: [Invitation] = []
    
    var acceptInvitationCalled = false
    var rejectInvitationCalled = false
    
    func createInvitation(psychologistEmail: String, patientId: String) async -> Result<Invitation, Error> {
        if shouldSucceed, let invitation = mockInvitation {
            return .success(invitation)
        } else {
            return .failure(mockError ?? NetworkError.unknown)
        }
    }
    
    func acceptInvitation(invitationId: String, psychologistId: String) async -> Result<Void, Error> {
        acceptInvitationCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? NetworkError.unknown)
        }
    }
    
    func rejectInvitation(invitationId: String, reason: String) async -> Result<Void, Error> {
        rejectInvitationCalled = true
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(mockError ?? NetworkError.unknown)
        }
    }
    
    func getPendingInvitations(for psychologistId: String) async -> Result<[Invitation], Error> {
        if shouldSucceed {
            return .success(mockInvitations)
        } else {
            return .failure(mockError ?? NetworkError.unknown)
        }
    }
}

enum NetworkError: Error {
    case connectionFailed
    case invalidResponse
    case unknown
}
