//
//  AppIntegrityValidatorTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

final class AppIntegrityValidatorTests: XCTestCase {
    
    var validator: AppIntegrityValidator!
    
    override func setUpWithError() throws {
        validator = AppIntegrityValidator.shared
    }
    
    override func tearDownWithError() throws {
        validator = nil
    }
    
    // MARK: - App Integrity Tests
    
    func testValidateAppIntegrityAsync() async throws {
        // When
        let result = await validator.validateAppIntegrity()
        
        // Then
        XCTAssertNotNil(result, "Should return a result")
        
        // Em ambiente de teste, algumas validações podem falhar
        // mas o resultado deve ter todos os campos preenchidos
        print("Integrity Result: \(result.toDictionary())")
        
        // Verificar que a estrutura está completa
        let dict = result.toDictionary()
        XCTAssertNotNil(dict["signature_valid"])
        XCTAssertNotNil(dict["files_integrity_valid"])
        XCTAssertNotNil(dict["bundle_integrity_valid"])
        XCTAssertNotNil(dict["resources_integrity_valid"])
        XCTAssertNotNil(dict["runtime_environment_valid"])
        XCTAssertNotNil(dict["overall_valid"])
    }
    
    func testIntegrityValidationResultStructure() throws {
        // Given
        var result = IntegrityValidationResult()
        
        // When
        result.signatureValid = true
        result.filesIntegrityValid = true
        result.bundleIntegrityValid = true
        result.resourcesIntegrityValid = true
        result.runtimeEnvironmentValid = true
        result.overallValid = true
        
        // Then
        let dict = result.toDictionary()
        XCTAssertEqual(dict["signature_valid"] as? Bool, true)
        XCTAssertEqual(dict["files_integrity_valid"] as? Bool, true)
        XCTAssertEqual(dict["bundle_integrity_valid"] as? Bool, true)
        XCTAssertEqual(dict["resources_integrity_valid"] as? Bool, true)
        XCTAssertEqual(dict["runtime_environment_valid"] as? Bool, true)
        XCTAssertEqual(dict["overall_valid"] as? Bool, true)
    }
    
    func testIntegrityValidationResultDefaults() throws {
        // Given
        let result = IntegrityValidationResult()
        
        // Then
        XCTAssertFalse(result.signatureValid, "Should default to false")
        XCTAssertFalse(result.filesIntegrityValid, "Should default to false")
        XCTAssertFalse(result.bundleIntegrityValid, "Should default to false")
        XCTAssertFalse(result.resourcesIntegrityValid, "Should default to false")
        XCTAssertFalse(result.runtimeEnvironmentValid, "Should default to false")
        XCTAssertFalse(result.overallValid, "Should default to false")
    }
    
    // MARK: - Performance Tests
    
    func testIntegrityValidationPerformance() async throws {
        measure {
            Task {
                _ = await validator.validateAppIntegrity()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testIntegrityValidationDoesNotCrash() async throws {
        // This test ensures that integrity validation handles errors gracefully
        // and doesn't crash the app
        
        var results: [IntegrityValidationResult] = []
        
        // Run multiple validations concurrently
        await withTaskGroup(of: IntegrityValidationResult.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    return await self.validator.validateAppIntegrity()
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        XCTAssertEqual(results.count, 5, "Should complete all validation tasks")
        
        for result in results {
            // Ensure all results have valid structure
            let dict = result.toDictionary()
            XCTAssertEqual(dict.keys.count, 6, "Should have all expected fields")
        }
    }
}