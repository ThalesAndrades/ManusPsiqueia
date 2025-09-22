//
//  UserTests.swift
//  ManusPsiqueiaTests
//
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 ManusPsiqueia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

final class UserTests: XCTestCase {
    
    // MARK: - User Initialization Tests
    
    func testUserInitialization_Patient() {
        // Given
        let id = "user_123"
        let email = "paciente@exemplo.com"
        let name = "João Silva"
        let userType = UserType.patient
        
        // When
        let user = User(
            id: id,
            email: email,
            name: name,
            userType: userType,
            createdAt: Date(),
            isActive: true
        )
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.userType, userType)
        XCTAssertTrue(user.isActive)
        XCTAssertNotNil(user.createdAt)
    }
    
    func testUserInitialization_Psychologist() {
        // Given
        let id = "psych_456"
        let email = "psicologo@exemplo.com"
        let name = "Dra. Maria Santos"
        let userType = UserType.psychologist
        let crp = "CRP 06/123456"
        
        // When
        let user = User(
            id: id,
            email: email,
            name: name,
            userType: userType,
            crp: crp,
            createdAt: Date(),
            isActive: true
        )
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.userType, userType)
        XCTAssertEqual(user.crp, crp)
        XCTAssertTrue(user.isActive)
    }
    
    // MARK: - User Type Tests
    
    func testUserType_Patient() {
        // Given
        let userType = UserType.patient
        
        // Then
        XCTAssertEqual(userType.rawValue, "patient")
        XCTAssertEqual(userType.displayName, "Paciente")
        XCTAssertFalse(userType.requiresSubscription)
    }
    
    func testUserType_Psychologist() {
        // Given
        let userType = UserType.psychologist
        
        // Then
        XCTAssertEqual(userType.rawValue, "psychologist")
        XCTAssertEqual(userType.displayName, "Psicólogo(a)")
        XCTAssertTrue(userType.requiresSubscription)
    }
    
    // MARK: - User Validation Tests
    
    func testEmailValidation_ValidEmails() {
        let validEmails = [
            "test@exemplo.com",
            "usuario.teste@dominio.com.br",
            "psicologo123@clinica.org",
            "paciente_novo@hospital.gov.br"
        ]
        
        for email in validEmails {
            let user = User(
                id: "test_id",
                email: email,
                name: "Test User",
                userType: .patient,
                createdAt: Date(),
                isActive: true
            )
            
            XCTAssertTrue(
                user.isValidEmail,
                "Email \(email) deveria ser válido"
            )
        }
    }
    
    func testEmailValidation_InvalidEmails() {
        let invalidEmails = [
            "email-sem-arroba",
            "@dominio.com",
            "usuario@",
            "usuario@dominio",
            "",
            "email com espaços@dominio.com"
        ]
        
        for email in invalidEmails {
            let user = User(
                id: "test_id",
                email: email,
                name: "Test User",
                userType: .patient,
                createdAt: Date(),
                isActive: true
            )
            
            XCTAssertFalse(
                user.isValidEmail,
                "Email \(email) deveria ser inválido"
            )
        }
    }
    
    func testCRPValidation_ValidCRPs() {
        let validCRPs = [
            "CRP 06/123456",
            "CRP 01/654321",
            "CRP 15/999999"
        ]
        
        for crp in validCRPs {
            let user = User(
                id: "psych_id",
                email: "psicologo@exemplo.com",
                name: "Dr. Teste",
                userType: .psychologist,
                crp: crp,
                createdAt: Date(),
                isActive: true
            )
            
            XCTAssertTrue(
                user.isValidCRP,
                "CRP \(crp) deveria ser válido"
            )
        }
    }
    
    func testCRPValidation_InvalidCRPs() {
        let invalidCRPs = [
            "123456",
            "CRP 123456",
            "CRP 06/",
            "CRP /123456",
            "",
            "CRP 99/123456" // Região inexistente
        ]
        
        for crp in invalidCRPs {
            let user = User(
                id: "psych_id",
                email: "psicologo@exemplo.com",
                name: "Dr. Teste",
                userType: .psychologist,
                crp: crp,
                createdAt: Date(),
                isActive: true
            )
            
            XCTAssertFalse(
                user.isValidCRP,
                "CRP \(crp) deveria ser inválido"
            )
        }
    }
    
    // MARK: - User Status Tests
    
    func testUserActivation() {
        // Given
        var user = User(
            id: "user_123",
            email: "test@exemplo.com",
            name: "Test User",
            userType: .patient,
            createdAt: Date(),
            isActive: false
        )
        
        // When
        user.activate()
        
        // Then
        XCTAssertTrue(user.isActive)
        XCTAssertNotNil(user.activatedAt)
    }
    
    func testUserDeactivation() {
        // Given
        var user = User(
            id: "user_123",
            email: "test@exemplo.com",
            name: "Test User",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        // When
        user.deactivate()
        
        // Then
        XCTAssertFalse(user.isActive)
        XCTAssertNotNil(user.deactivatedAt)
    }
    
    // MARK: - User Profile Tests
    
    func testUpdateProfile() {
        // Given
        var user = User(
            id: "user_123",
            email: "old@exemplo.com",
            name: "Old Name",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        let newName = "New Name"
        let newPhone = "+55 11 99999-9999"
        
        // When
        user.updateProfile(name: newName, phone: newPhone)
        
        // Then
        XCTAssertEqual(user.name, newName)
        XCTAssertEqual(user.phone, newPhone)
        XCTAssertNotNil(user.updatedAt)
    }
    
    // MARK: - User Subscription Tests
    
    func testPsychologistRequiresSubscription() {
        // Given
        let psychologist = User(
            id: "psych_123",
            email: "psicologo@exemplo.com",
            name: "Dr. Teste",
            userType: .psychologist,
            crp: "CRP 06/123456",
            createdAt: Date(),
            isActive: true
        )
        
        // Then
        XCTAssertTrue(psychologist.requiresSubscription)
    }
    
    func testPatientDoesNotRequireSubscription() {
        // Given
        let patient = User(
            id: "patient_123",
            email: "paciente@exemplo.com",
            name: "João Silva",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        // Then
        XCTAssertFalse(patient.requiresSubscription)
    }
    
    // MARK: - User Equality Tests
    
    func testUserEquality() {
        // Given
        let user1 = User(
            id: "user_123",
            email: "test@exemplo.com",
            name: "Test User",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        let user2 = User(
            id: "user_123",
            email: "different@exemplo.com",
            name: "Different Name",
            userType: .psychologist,
            createdAt: Date(),
            isActive: false
        )
        
        let user3 = User(
            id: "user_456",
            email: "test@exemplo.com",
            name: "Test User",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        // Then
        XCTAssertEqual(user1, user2) // Mesma ID
        XCTAssertNotEqual(user1, user3) // IDs diferentes
    }
    
    // MARK: - User JSON Encoding/Decoding Tests
    
    func testUserJSONEncoding() throws {
        // Given
        let user = User(
            id: "user_123",
            email: "test@exemplo.com",
            name: "Test User",
            userType: .patient,
            createdAt: Date(),
            isActive: true
        )
        
        // When
        let jsonData = try JSONEncoder().encode(user)
        let decodedUser = try JSONDecoder().decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.id, decodedUser.id)
        XCTAssertEqual(user.email, decodedUser.email)
        XCTAssertEqual(user.name, decodedUser.name)
        XCTAssertEqual(user.userType, decodedUser.userType)
        XCTAssertEqual(user.isActive, decodedUser.isActive)
    }
}
