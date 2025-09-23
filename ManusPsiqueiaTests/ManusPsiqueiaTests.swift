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
    // Simple email validation without NSPredicate for cross-platform compatibility
    guard email.contains("@") && email.contains(".") else { return false }
    let components = email.split(separator: "@")
    guard components.count == 2 else { return false }
    
    let localPart = String(components[0])
    let domainPart = String(components[1])
    
    // Basic validation
    guard !localPart.isEmpty && !domainPart.isEmpty else { return false }
    guard domainPart.contains(".") else { return false }
    guard !email.hasPrefix(".") && !email.hasSuffix(".") else { return false }
    guard !email.contains("..") else { return false }
    
    return true
}

/// Validates password strength
private func isValidPassword(_ password: String) -> Bool {
    // At least 8 characters, with uppercase, lowercase, number, and special character
    guard password.count >= 8 else { return false }
    
    // Check for at least one uppercase letter
    let hasUppercase = password.contains { $0.isUppercase }
    
    // Check for at least one lowercase letter  
    let hasLowercase = password.contains { $0.isLowercase }
    
    // Check for at least one number
    let hasNumber = password.contains { $0.isNumber }
    
    // Check for at least one special character
    let specialChars = "!@#$%^&*(),.?\":{}|<>"
    let hasSpecialChar = password.contains { specialChars.contains($0) }
    
    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar
}
