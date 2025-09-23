//
//  ManusPsiqueiaTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServicesCore
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServicesUI
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServicesServices

/// Suite principal de testes para ManusPsiqueia
/// Cobertura objetivo: 85%+ para garantir qualidade enterprise
final class ManusPsiqueiaTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Configuração inicial para todos os testes
        continueAfterFailure = false
        
        // Initialize modules for testing
        ManusPsiqueiaCore.initialize()
        ManusPsiqueiaUI.initialize()
        ManusPsiqueiaServices.initialize()
    }

    override func tearDownWithError() throws {
        // Limpeza após cada teste
    }

    /// Teste de exemplo para verificar configuração
    func testExample() throws {
        // Teste básico para validar setup
        XCTAssertTrue(true, "Configuração de testes funcionando")
    }
    
    func testModuleInitialization() throws {
        // Test that all modules initialize properly
        XCTAssertEqual(ManusPsiqueiaCore.version, "1.0.0")
        XCTAssertEqual(ManusPsiqueiaUI.version, "1.0.0")
        XCTAssertEqual(ManusPsiqueiaServices.version, "1.0.0")
    }
    
    func testUserModelCreation() throws {
        // Test basic User model functionality
        let user = User(
            id: UUID(),
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            userType: .patient,
            profileImageURL: nil,
            phone: nil,
            dateOfBirth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(user.fullName, "Test User")
        XCTAssertEqual(user.userType, .patient)
        XCTAssertEqual(user.email, "test@example.com")
    }

    /// Teste de performance de exemplo
    func testPerformanceExample() throws {
        measure {
            // Medição de performance básica
            _ = User(
                id: UUID(),
                email: "performance@test.com",
                firstName: "Performance",
                lastName: "Test",
                userType: .psychologist,
                profileImageURL: nil,
                phone: nil,
                dateOfBirth: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
}
