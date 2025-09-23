//
//  UserModelTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

/// Testes para o modelo User
/// Cobertura: Criação, validação, serialização e business rules
final class UserModelTests: XCTestCase {
    
    var samplePsychologist: User!
    var samplePatient: User!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Criar usuários de exemplo para testes
        samplePsychologist = User(
            id: UUID(),
            email: "psicologo@teste.com",
            name: "Dr. João Silva",
            userType: .psychologist,
            isActive: true,
            createdAt: Date(),
            profileData: PsychologistProfile(
                crp: "12345-SP",
                specializations: ["Ansiedade", "Depressão"],
                experience: 5,
                bio: "Psicólogo especializado em terapia cognitivo-comportamental"
            )
        )
        
        samplePatient = User(
            id: UUID(),
            email: "paciente@teste.com",
            name: "Maria Santos",
            userType: .patient,
            isActive: true,
            createdAt: Date(),
            profileData: PatientProfile(
                birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
                emergencyContact: "11999999999",
                medicalHistory: "Histórico de ansiedade"
            )
        )
    }
    
    override func tearDownWithError() throws {
        samplePsychologist = nil
        samplePatient = nil
        super.tearDown()
    }
    
    // MARK: - Testes de Criação
    
    func testUserCreation() throws {
        XCTAssertNotNil(samplePsychologist)
        XCTAssertNotNil(samplePatient)
        XCTAssertEqual(samplePsychologist.userType, .psychologist)
        XCTAssertEqual(samplePatient.userType, .patient)
    }
    
    func testPsychologistProfileValidation() throws {
        XCTAssertTrue(samplePsychologist.isPsychologist)
        XCTAssertFalse(samplePsychologist.isPatient)
        
        if case .psychologist(let profile) = samplePsychologist.profileData {
            XCTAssertEqual(profile.crp, "12345-SP")
            XCTAssertEqual(profile.specializations.count, 2)
            XCTAssertEqual(profile.experience, 5)
        } else {
            XCTFail("Profile data should be psychologist type")
        }
    }
    
    func testPatientProfileValidation() throws {
        XCTAssertTrue(samplePatient.isPatient)
        XCTAssertFalse(samplePatient.isPsychologist)
        
        if case .patient(let profile) = samplePatient.profileData {
            XCTAssertNotNil(profile.birthDate)
            XCTAssertEqual(profile.emergencyContact, "11999999999")
        } else {
            XCTFail("Profile data should be patient type")
        }
    }
    
    // MARK: - Testes de Validação
    
    func testEmailValidation() throws {
        XCTAssertTrue(samplePsychologist.isValidEmail)
        XCTAssertTrue(samplePatient.isValidEmail)
        
        // Teste com email inválido
        var invalidUser = samplePsychologist!
        invalidUser.email = "email-invalido"
        XCTAssertFalse(invalidUser.isValidEmail)
    }
    
    func testCRPValidation() throws {
        if case .psychologist(let profile) = samplePsychologist.profileData {
            XCTAssertTrue(profile.isValidCRP)
        }
        
        // Teste com CRP inválido
        var invalidProfile = PsychologistProfile(
            crp: "123",
            specializations: ["Teste"],
            experience: 1,
            bio: "Teste"
        )
        XCTAssertFalse(invalidProfile.isValidCRP)
    }
    
    // MARK: - Testes de Serialização
    
    func testUserSerialization() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Teste serialização psicólogo
        let psychologistData = try encoder.encode(samplePsychologist)
        let decodedPsychologist = try decoder.decode(User.self, from: psychologistData)
        
        XCTAssertEqual(samplePsychologist.id, decodedPsychologist.id)
        XCTAssertEqual(samplePsychologist.email, decodedPsychologist.email)
        XCTAssertEqual(samplePsychologist.userType, decodedPsychologist.userType)
        
        // Teste serialização paciente
        let patientData = try encoder.encode(samplePatient)
        let decodedPatient = try decoder.decode(User.self, from: patientData)
        
        XCTAssertEqual(samplePatient.id, decodedPatient.id)
        XCTAssertEqual(samplePatient.email, decodedPatient.email)
        XCTAssertEqual(samplePatient.userType, decodedPatient.userType)
    }
    
    // MARK: - Testes de Business Rules
    
    func testUserActivation() throws {
        XCTAssertTrue(samplePsychologist.isActive)
        
        samplePsychologist.deactivate()
        XCTAssertFalse(samplePsychologist.isActive)
        
        samplePsychologist.activate()
        XCTAssertTrue(samplePsychologist.isActive)
    }
    
    func testUserAge() throws {
        if case .patient(let profile) = samplePatient.profileData {
            let age = profile.age
            XCTAssertEqual(age, 30, accuracy: 1)
        }
    }
    
    // MARK: - Testes de Performance
    
    func testUserCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = User(
                    id: UUID(),
                    email: "teste@teste.com",
                    name: "Teste",
                    userType: .patient,
                    isActive: true,
                    createdAt: Date(),
                    profileData: PatientProfile(
                        birthDate: Date(),
                        emergencyContact: "11999999999",
                        medicalHistory: "Teste"
                    )
                )
            }
        }
    }
}
