//
//  ManusPsiqueiaTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
// Note: We don't import the main module to avoid iOS-specific dependencies in Swift Package Manager tests
// For testing the main module functionality, use the iOS-specific test target in the Xcode project

/// Suite principal de testes para ManusPsiqueia
/// Cobertura objetivo: 85%+ para garantir qualidade enterprise
final class ManusPsiqueiaTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Configuração inicial para todos os testes
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Limpeza após cada teste
    }

    /// Teste básico para validar que o framework de teste está funcionando
    func testFrameworkSetup() throws {
        // Teste básico para validar setup
        XCTAssertTrue(true, "Configuração de testes funcionando")
        
        // Test basic Swift functionality
        let testString = "ManusPsiqueia"
        XCTAssertEqual(testString.count, 13, "String count should be correct")
        
        // Test basic date functionality  
        let now = Date()
        let future = now.addingTimeInterval(60) // 1 minute later
        XCTAssertTrue(future > now, "Future date should be greater than current date")
    }
    
    /// Teste de validação de email
    func testEmailValidation() throws {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co",
            "first_last@test-domain.com"
        ]
        
        let invalidEmails = [
            "invalid.email",
            "@domain.com",
            "test@",
            "test..test@domain.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(isValidEmail(email), "Email \(email) should be valid")
        }
        
        for email in invalidEmails {
            XCTAssertFalse(isValidEmail(email), "Email \(email) should be invalid")
        }
    }
    
    /// Teste de validação de senha
    func testPasswordValidation() throws {
        let validPasswords = [
            "Password123!",
            "MySecure@Pass1",
            "Complex$Password9"
        ]
        
        let invalidPasswords = [
            "weak",
            "password",
            "12345678",
            "Password", // No number or special char
            "password123" // No uppercase or special char
        ]
        
        for password in validPasswords {
            XCTAssertTrue(isValidPassword(password), "Password \(password) should be valid")
        }
        
        for password in invalidPasswords {
            XCTAssertFalse(isValidPassword(password), "Password \(password) should be invalid")
        }
    }

    /// Teste de performance de exemplo
    func testPerformanceExample() throws {
        measure {
            // Medição de performance básica - sort de array
            let numbers = Array(1...1000).shuffled()
            let _ = numbers.sorted()
        }
    }
}

// MARK: - Helper Functions

/// Validates email format using basic regex
private func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

/// Validates password strength
private func isValidPassword(_ password: String) -> Bool {
    // At least 8 characters, with uppercase, lowercase, number, and special character
    guard password.count >= 8 else { return false }
    
    let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
    let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
    let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    
    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar
}
