//
//  APIKeyObfuscatorTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

final class APIKeyObfuscatorTests: XCTestCase {
    
    var obfuscator: APIKeyObfuscator!
    
    override func setUpWithError() throws {
        obfuscator = APIKeyObfuscator.shared
    }
    
    override func tearDownWithError() throws {
        obfuscator = nil
    }
    
    // MARK: - Obfuscation Tests
    
    func testObfuscateAndDeobfuscateAPIKey() throws {
        // Given
        let originalKey = "pk_test_1234567890abcdef"
        
        // When
        let obfuscatedData = obfuscator.obfuscateAPIKey(originalKey)
        
        // Then
        XCTAssertNotNil(obfuscatedData, "Obfuscation should succeed")
        
        // When deobfuscating
        let deobfuscatedKey = obfuscator.deobfuscateAPIKey(obfuscatedData!)
        
        // Then
        XCTAssertEqual(deobfuscatedKey, originalKey, "Deobfuscated key should match original")
    }
    
    func testObfuscateEmptyKey() throws {
        // Given
        let emptyKey = ""
        
        // When
        let obfuscatedData = obfuscator.obfuscateAPIKey(emptyKey)
        
        // Then
        XCTAssertNil(obfuscatedData, "Empty key obfuscation should fail")
    }
    
    func testDeobfuscateInvalidData() throws {
        // Given
        let invalidData = Data([0x00, 0x01, 0x02])
        
        // When
        let deobfuscatedKey = obfuscator.deobfuscateAPIKey(invalidData)
        
        // Then
        XCTAssertNil(deobfuscatedKey, "Invalid data deobfuscation should fail")
    }
    
    // MARK: - Key Validation Tests
    
    func testValidateStripeKeyFormat() throws {
        // Valid Stripe keys
        XCTAssertTrue(obfuscator.validateAPIKeyFormat("pk_test_1234567890", type: .stripe))
        XCTAssertTrue(obfuscator.validateAPIKeyFormat("pk_live_1234567890", type: .stripe))
        XCTAssertTrue(obfuscator.validateAPIKeyFormat("sk_test_1234567890", type: .stripe))
        
        // Invalid Stripe keys
        XCTAssertFalse(obfuscator.validateAPIKeyFormat("invalid_key", type: .stripe))
        XCTAssertFalse(obfuscator.validateAPIKeyFormat("", type: .stripe))
    }
    
    func testValidateOpenAIKeyFormat() throws {
        // Valid OpenAI key
        XCTAssertTrue(obfuscator.validateAPIKeyFormat("sk-1234567890abcdefghijklmnop", type: .openAI))
        
        // Invalid OpenAI keys
        XCTAssertFalse(obfuscator.validateAPIKeyFormat("sk-short", type: .openAI))
        XCTAssertFalse(obfuscator.validateAPIKeyFormat("invalid_key", type: .openAI))
        XCTAssertFalse(obfuscator.validateAPIKeyFormat("", type: .openAI))
    }
    
    func testValidateSupabaseKeyFormat() throws {
        // Valid Supabase key (long key)
        let longKey = String(repeating: "a", count: 51)
        XCTAssertTrue(obfuscator.validateAPIKeyFormat(longKey, type: .supabase))
        
        // Invalid Supabase key (too short)
        let shortKey = String(repeating: "a", count: 10)
        XCTAssertFalse(obfuscator.validateAPIKeyFormat(shortKey, type: .supabase))
    }
    
    // MARK: - Security Hash Tests
    
    func testGenerateSecureHash() throws {
        // Given
        let key = "test_key_12345"
        
        // When
        let hash1 = obfuscator.generateSecureHash(for: key)
        let hash2 = obfuscator.generateSecureHash(for: key)
        
        // Then
        XCTAssertEqual(hash1, hash2, "Same key should generate same hash")
        XCTAssertEqual(hash1.count, 8, "Hash should be 8 characters long")
        
        // Different keys should generate different hashes
        let differentKey = "different_key"
        let differentHash = obfuscator.generateSecureHash(for: differentKey)
        XCTAssertNotEqual(hash1, differentHash, "Different keys should generate different hashes")
    }
    
    // MARK: - Key Integrity Tests
    
    func testVerifyKeyIntegrity() throws {
        // When
        let integrityValid = obfuscator.verifyKeyIntegrity()
        
        // Then
        // This should succeed even with fallback keys from ConfigurationManager
        XCTAssertTrue(integrityValid, "Key integrity verification should pass")
    }
    
    // MARK: - Performance Tests
    
    func testObfuscationPerformance() throws {
        let key = "pk_test_1234567890abcdefghijklmnopqrstuvwxyz"
        
        measure {
            for _ in 0..<100 {
                if let obfuscated = obfuscator.obfuscateAPIKey(key) {
                    _ = obfuscator.deobfuscateAPIKey(obfuscated)
                }
            }
        }
    }
}