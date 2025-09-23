//
//  NetworkErrorTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueia

final class NetworkErrorTests: XCTestCase {
    
    func testNetworkErrorDescriptions() throws {
        let invalidURLError = NetworkError.invalidURL("invalid-url")
        XCTAssertTrue(invalidURLError.errorDescription?.contains("URL inválida") == true)
        
        let noInternetError = NetworkError.noInternetConnection
        XCTAssertTrue(noInternetError.errorDescription?.contains("Sem conexão") == true)
        
        let unauthorizedError = NetworkError.unauthorized
        XCTAssertTrue(unauthorizedError.errorDescription?.contains("autenticação") == true)
        
        let rateLimitedError = NetworkError.rateLimited
        XCTAssertTrue(rateLimitedError.errorDescription?.contains("requisições") == true)
    }
    
    func testHTTPErrorMessages() throws {
        let error400 = NetworkError.httpError(statusCode: 400)
        XCTAssertTrue(error400.errorDescription?.contains("400") == true)
        
        let error404 = NetworkError.httpError(statusCode: 404)
        XCTAssertTrue(error404.errorDescription?.contains("404") == true)
        
        let error500 = NetworkError.httpError(statusCode: 500)
        XCTAssertTrue(error500.errorDescription?.contains("500") == true)
    }
    
    func testErrorCategories() throws {
        // Connectivity errors
        XCTAssertTrue(NetworkError.noInternetConnection.isConnectivityError)
        XCTAssertTrue(NetworkError.timeout.isConnectivityError)
        XCTAssertFalse(NetworkError.unauthorized.isConnectivityError)
        
        // Authentication errors
        XCTAssertTrue(NetworkError.unauthorized.isAuthenticationError)
        XCTAssertTrue(NetworkError.httpError(statusCode: 401).isAuthenticationError)
        XCTAssertTrue(NetworkError.httpError(statusCode: 403).isAuthenticationError)
        XCTAssertFalse(NetworkError.noInternetConnection.isAuthenticationError)
        
        // Retryable errors
        XCTAssertTrue(NetworkError.noInternetConnection.isRetryable)
        XCTAssertTrue(NetworkError.timeout.isRetryable)
        XCTAssertTrue(NetworkError.httpError(statusCode: 500).isRetryable)
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
        
        // Requires user action
        XCTAssertTrue(NetworkError.unauthorized.requiresUserAction)
        XCTAssertTrue(NetworkError.httpError(statusCode: 401).requiresUserAction)
        XCTAssertFalse(NetworkError.noInternetConnection.requiresUserAction)
    }
    
    func testErrorEquality() throws {
        let error1 = NetworkError.noInternetConnection
        let error2 = NetworkError.noInternetConnection
        XCTAssertEqual(error1, error2)
        
        let httpError1 = NetworkError.httpError(statusCode: 404)
        let httpError2 = NetworkError.httpError(statusCode: 404)
        XCTAssertEqual(httpError1, httpError2)
        
        let httpError3 = NetworkError.httpError(statusCode: 500)
        XCTAssertNotEqual(httpError1, httpError3)
        
        let urlError1 = NetworkError.invalidURL("test1")
        let urlError2 = NetworkError.invalidURL("test1")
        let urlError3 = NetworkError.invalidURL("test2")
        XCTAssertEqual(urlError1, urlError2)
        XCTAssertNotEqual(urlError1, urlError3)
    }
    
    func testErrorFactoryFromURLError() throws {
        let urlError = URLError(.notConnectedToInternet)
        let networkError = NetworkError.from(urlError: urlError)
        XCTAssertEqual(networkError, NetworkError.noInternetConnection)
        
        let timeoutError = URLError(.timedOut)
        let timeoutNetworkError = NetworkError.from(urlError: timeoutError)
        XCTAssertEqual(timeoutNetworkError, NetworkError.timeout)
    }
    
    func testErrorFactoryFromHTTPStatus() throws {
        let unauthorizedError = NetworkError.from(httpStatusCode: 401)
        XCTAssertEqual(unauthorizedError, NetworkError.unauthorized)
        
        let rateLimitError = NetworkError.from(httpStatusCode: 429)
        XCTAssertEqual(rateLimitError, NetworkError.rateLimited)
        
        let serverError = NetworkError.from(httpStatusCode: 500)
        XCTAssertEqual(serverError, NetworkError.httpError(statusCode: 500))
    }
    
    func testDecodingErrorFactory() throws {
        let decodingError = DecodingError.keyNotFound(
            CodingKeys.testKey,
            DecodingError.Context(codingPath: [], debugDescription: "Test error")
        )
        
        let networkError = NetworkError.from(decodingError: decodingError)
        
        if case .decodingError(let description) = networkError {
            XCTAssertTrue(description.contains("Chave não encontrada"))
        } else {
            XCTFail("Expected decodingError case")
        }
    }
    
    func testRecoverySuggestions() throws {
        let noInternetError = NetworkError.noInternetConnection
        XCTAssertTrue(noInternetError.recoverySuggestion?.contains("rede") == true)
        
        let unauthorizedError = NetworkError.unauthorized
        XCTAssertTrue(unauthorizedError.recoverySuggestion?.contains("login") == true)
        
        let rateLimitError = NetworkError.rateLimited
        XCTAssertTrue(rateLimitError.recoverySuggestion?.contains("minuto") == true)
    }
}

// MARK: - Test Helpers

private enum CodingKeys: String, CodingKey {
    case testKey = "test_key"
}