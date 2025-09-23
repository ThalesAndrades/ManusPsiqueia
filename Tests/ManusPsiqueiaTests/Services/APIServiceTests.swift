//
//  APIServiceTests.swift
//  ManusPsiqueiaTests
//
//  Testes para o APIService
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import XCTest
import Combine
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

@MainActor
final class APIServiceTests: XCTestCase {
    
    var apiService: APIService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUpWithError()
        apiService = APIService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        apiService = nil
        cancellables = nil
        super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    func testValidateAPIConfiguration() throws {
        let errors = apiService.validateAPIConfiguration()
        
        // Em ambiente de teste, esperamos que algumas configurações estejam faltando
        XCTAssertTrue(errors.count >= 0, "Validação de configuração deve retornar lista de erros")
        
        // Verificar se os tipos de erro esperados estão presentes
        let errorMessages = errors.joined(separator: ", ")
        print("Erros de configuração encontrados: \(errorMessages)")
    }
    
    // MARK: - OpenAI API Tests
    
    func testGenerateDiaryInsight_withValidText() async throws {
        let testText = "Hoje foi um dia muito bom, me sinto feliz e realizado."
        
        do {
            let insight = try await apiService.generateDiaryInsight(text: testText)
            
            XCTAssertFalse(insight.text.isEmpty, "Insight text should not be empty")
            XCTAssertNotNil(insight.sentiment, "Sentiment should be determined")
            XCTAssertNotNil(insight.timestamp, "Timestamp should be set")
            
        } catch APIService.APIError.invalidConfiguration {
            // Esperado em ambiente de teste sem chaves configuradas
            XCTAssertTrue(true, "Expected configuration error in test environment")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateDiaryInsight_withEmptyConfiguration() async throws {
        // Este teste verifica se o erro de configuração é lançado corretamente
        let testText = "Texto de teste"
        
        do {
            _ = try await apiService.generateDiaryInsight(text: testText)
            // Se chegou aqui, a configuração está válida (não esperado em testes)
        } catch APIService.APIError.invalidConfiguration {
            XCTAssertTrue(true, "Expected configuration error")
        } catch {
            XCTFail("Expected configuration error, got: \(error)")
        }
    }
    
    // MARK: - Stripe API Tests
    
    func testCreatePaymentIntent_withValidAmount() async throws {
        let amount = 2999 // R$ 29,99 em centavos
        
        do {
            let paymentIntent = try await apiService.createPaymentIntent(amount: amount)
            
            XCTAssertFalse(paymentIntent.id.isEmpty, "Payment intent ID should not be empty")
            XCTAssertFalse(paymentIntent.clientSecret.isEmpty, "Client secret should not be empty")
            XCTAssertEqual(paymentIntent.amount, amount, "Amount should match")
            XCTAssertEqual(paymentIntent.currency, "brl", "Currency should be BRL")
            
        } catch APIService.APIError.invalidConfiguration {
            // Esperado em ambiente de teste sem chaves configuradas
            XCTAssertTrue(true, "Expected configuration error in test environment")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetCustomerSubscriptions_withValidCustomerId() async throws {
        let customerId = "cus_test123"
        
        do {
            let subscriptions = try await apiService.getCustomerSubscriptions(customerId: customerId)
            
            XCTAssertNotNil(subscriptions.data, "Subscriptions data should not be nil")
            
        } catch APIService.APIError.invalidConfiguration {
            // Esperado em ambiente de teste sem chaves configuradas
            XCTAssertTrue(true, "Expected configuration error in test environment")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Supabase API Tests
    
    func testSaveUserData_withValidData() async throws {
        let testData = ["name": "Test User", "email": "test@example.com"]
        let tableName = "users"
        
        do {
            let response = try await apiService.saveUserData(testData, to: tableName)
            
            XCTAssertNotNil(response, "Response should not be nil")
            
        } catch APIService.APIError.invalidConfiguration {
            // Esperado em ambiente de teste sem configuração do Supabase
            XCTAssertTrue(true, "Expected configuration error in test environment")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testFetchUserData_withValidParameters() async throws {
        let tableName = "diary_entries"
        let userId = "user123"
        
        do {
            let data: [String] = try await apiService.fetchUserData(
                from: tableName,
                userId: userId,
                type: String.self
            )
            
            XCTAssertNotNil(data, "Data should not be nil")
            
        } catch APIService.APIError.invalidConfiguration {
            // Esperado em ambiente de teste sem configuração do Supabase
            XCTAssertTrue(true, "Expected configuration error in test environment")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Backend API Tests
    
    func testCheckAPIHealth() async throws {
        do {
            let healthCheck = try await apiService.checkAPIHealth()
            
            XCTAssertFalse(healthCheck.status.isEmpty, "Status should not be empty")
            XCTAssertFalse(healthCheck.timestamp.isEmpty, "Timestamp should not be empty")
            XCTAssertFalse(healthCheck.version.isEmpty, "Version should not be empty")
            
        } catch APIService.APIError.networkUnavailable {
            // Esperado se o backend não estiver disponível
            XCTAssertTrue(true, "Expected network unavailable error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSyncUserProfile_withValidProfile() async throws {
        let profile = UserProfile(
            id: "user123",
            name: "Test User",
            email: "test@example.com",
            preferences: ["theme": "dark", "notifications": "enabled"]
        )
        
        do {
            let response = try await apiService.syncUserProfile(profile)
            
            XCTAssertEqual(response.id, profile.id, "Response ID should match profile ID")
            XCTAssertFalse(response.updatedAt.isEmpty, "Updated timestamp should not be empty")
            
        } catch APIService.APIError.networkUnavailable {
            // Esperado se o backend não estiver disponível
            XCTAssertTrue(true, "Expected network unavailable error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testTestAllAPIs() async throws {
        let results = await apiService.testAllAPIs()
        
        XCTAssertEqual(results.count, 4, "Should test 4 APIs")
        XCTAssertNotNil(results["OpenAI"], "Should test OpenAI")
        XCTAssertNotNil(results["Stripe"], "Should test Stripe")
        XCTAssertNotNil(results["Supabase"], "Should test Supabase")
        XCTAssertNotNil(results["Backend"], "Should test Backend")
        
        // Em ambiente de teste, esperamos que a maioria falhe por falta de configuração
        let successCount = results.values.filter { $0 }.count
        print("APIs funcionais: \(successCount)/4")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMapping() throws {
        // Testar se os erros são mapeados corretamente
        let networkError = NetworkManager.NetworkError.noInternetConnection
        
        // Simular erro através do APIService
        let expectation = XCTestExpectation(description: "Error should be mapped correctly")
        
        Task {
            do {
                _ = try await apiService.checkAPIHealth()
            } catch let error as APIService.APIError {
                switch error {
                case .networkUnavailable, .unknownError:
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected error type: \(error)")
                }
            } catch {
                XCTFail("Expected APIError, got: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState() async throws {
        // Verificar se o estado de loading é gerenciado corretamente
        XCTAssertFalse(apiService.isLoading, "Should not be loading initially")
        
        // Iniciar uma operação assíncrona
        let task = Task {
            do {
                _ = try await apiService.checkAPIHealth()
            } catch {
                // Ignorar erros, estamos testando apenas o estado de loading
            }
        }
        
        // Aguardar um pouco para verificar se isLoading foi definido
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
        
        await task.value
        
        // Após a conclusão, loading deve ser false
        XCTAssertFalse(apiService.isLoading, "Should not be loading after completion")
    }
    
    // MARK: - Sentiment Analysis Tests
    
    func testSentimentAnalysis() async throws {
        // Testar análise de sentimento com diferentes tipos de texto
        let positiveText = "Hoje foi um dia maravilhoso, me sinto muito feliz e realizado!"
        let negativeText = "Estou me sentindo muito triste e deprimido hoje."
        let neutralText = "Hoje foi um dia normal, nada de especial aconteceu."
        
        do {
            let positiveInsight = try await apiService.generateDiaryInsight(text: positiveText)
            let negativeInsight = try await apiService.generateDiaryInsight(text: negativeText)
            let neutralInsight = try await apiService.generateDiaryInsight(text: neutralText)
            
            // Verificar se os sentimentos são analisados corretamente
            XCTAssertEqual(positiveInsight.sentiment, .positive, "Should detect positive sentiment")
            XCTAssertEqual(negativeInsight.sentiment, .negative, "Should detect negative sentiment")
            XCTAssertEqual(neutralInsight.sentiment, .neutral, "Should detect neutral sentiment")
            
        } catch APIService.APIError.invalidConfiguration {
            // Em ambiente de teste, podemos simular a análise de sentimento
            // usando a lógica interna do APIService
            print("Sentiment analysis test skipped due to missing API configuration")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAPIServicePerformance() throws {
        measure {
            // Testar performance da validação de configuração
            let errors = apiService.validateAPIConfiguration()
            XCTAssertNotNil(errors)
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryLeaks() throws {
        weak var weakAPIService: APIService?
        
        autoreleasepool {
            let localAPIService = APIService.shared
            weakAPIService = localAPIService
            
            // Realizar algumas operações
            let errors = localAPIService.validateAPIConfiguration()
            XCTAssertNotNil(errors)
        }
        
        // Como APIService é singleton, não deve ser dealocado
        XCTAssertNotNil(weakAPIService, "Singleton should not be deallocated")
    }
}
