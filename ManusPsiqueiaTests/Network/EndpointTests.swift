//
//  EndpointTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

final class EndpointTests: XCTestCase {
    
    func testOpenAIEndpoint() throws {
        let apiKey = "test-api-key"
        let endpoint = OpenAIEndpoint.chatCompletions(apiKey: apiKey)
        
        XCTAssertEqual(endpoint.path, "/chat/completions")
        XCTAssertEqual(endpoint.method, .POST)
        XCTAssertEqual(endpoint.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(endpoint.headers?["Authorization"], "Bearer \(apiKey)")
    }
    
    func testStripeEndpoint() throws {
        let apiKey = "test-stripe-key"
        let endpoint = StripeEndpoint.paymentIntents(apiKey: apiKey)
        
        XCTAssertEqual(endpoint.path, "/payment_intents")
        XCTAssertEqual(endpoint.method, .POST)
        XCTAssertEqual(endpoint.baseURL, "https://api.stripe.com/v1")
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.stripe.com/v1/payment_intents")
        XCTAssertEqual(endpoint.headers?["Authorization"], "Bearer \(apiKey)")
    }
    
    func testSupabaseEndpoint() throws {
        let anonKey = "test-anon-key"
        let tableName = "users"
        let environment = ConfigurationManager.Environment.development
        
        let endpoint = SupabaseEndpoint.table(tableName, environment: environment, anonKey: anonKey)
        
        XCTAssertEqual(endpoint.path, "/users")
        XCTAssertEqual(endpoint.method, .POST)
        XCTAssertEqual(endpoint.baseURL, "https://dev-project.supabase.co/rest/v1")
        XCTAssertEqual(endpoint.url?.absoluteString, "https://dev-project.supabase.co/rest/v1/users")
        XCTAssertEqual(endpoint.headers?["apikey"], anonKey)
        XCTAssertEqual(endpoint.headers?["Authorization"], "Bearer \(anonKey)")
    }
    
    func testManusAPIEndpoint() throws {
        let environment = ConfigurationManager.Environment.production
        let endpoint = ManusAPIEndpoint.health(environment: environment)
        
        XCTAssertEqual(endpoint.path, "/health")
        XCTAssertEqual(endpoint.method, .GET)
        XCTAssertEqual(endpoint.baseURL, "https://api.manuspsiqueia.com/v1")
        XCTAssertEqual(endpoint.url?.absoluteString, "https://api.manuspsiqueia.com/v1/health")
    }
    
    func testEnvironmentSpecificURLs() throws {
        // Test different environments for ManusAPI
        let devEndpoint = ManusAPIEndpoint.health(environment: .development)
        XCTAssertEqual(devEndpoint.baseURL, "https://api-dev.manuspsiqueia.com/v1")
        
        let stagingEndpoint = ManusAPIEndpoint.health(environment: .staging)
        XCTAssertEqual(stagingEndpoint.baseURL, "https://api-staging.manuspsiqueia.com/v1")
        
        let prodEndpoint = ManusAPIEndpoint.health(environment: .production)
        XCTAssertEqual(prodEndpoint.baseURL, "https://api.manuspsiqueia.com/v1")
    }
    
    func testHTTPMethods() throws {
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    func testEndpointDefaultHeaders() throws {
        let endpoint = OpenAIEndpoint.chatCompletions(apiKey: "test")
        let allHeaders = endpoint.allHeaders
        
        XCTAssertEqual(allHeaders["Content-Type"], "application/json")
        XCTAssertEqual(allHeaders["Accept"], "application/json")
        XCTAssertEqual(allHeaders["Authorization"], "Bearer test")
    }
}