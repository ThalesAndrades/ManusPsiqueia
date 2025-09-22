//
//  APIService.swift
//  ManusPsiqueia
//
//  Serviço centralizado para integração com todas as APIs externas
//  Created by Manus AI on 2025-09-22.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import Combine

// MARK: - API Service

@MainActor
final class APIService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = APIService()
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = false
    @Published var lastError: APIError?
    
    // MARK: - Private Properties
    
    private let networkManager = NetworkManager.shared
    private let configManager = ConfigurationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - API Endpoints
    
    private struct Endpoints {
        static let openAI = "https://api.openai.com/v1"
        static let stripe = "https://api.stripe.com/v1"
        
        static func manusAPI(environment: ConfigurationManager.Environment) -> String {
            switch environment {
            case .development:
                return "https://api-dev.manuspsiqueia.com/v1"
            case .staging:
                return "https://api-staging.manuspsiqueia.com/v1"
            case .production:
                return "https://api.manuspsiqueia.com/v1"
            }
        }
        
        static func supabase(environment: ConfigurationManager.Environment) -> String {
            switch environment {
            case .development:
                return "https://dev-project.supabase.co/rest/v1"
            case .staging:
                return "https://staging-project.supabase.co/rest/v1"
            case .production:
                return "https://prod-project.supabase.co/rest/v1"
            }
        }
    }
    
    // MARK: - API Errors
    
    enum APIError: LocalizedError {
        case invalidConfiguration
        case networkUnavailable
        case authenticationFailed
        case rateLimitExceeded
        case serverError(Int)
        case decodingError
        case unknownError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidConfiguration:
                return "Configuração da API inválida"
            case .networkUnavailable:
                return "Rede indisponível"
            case .authenticationFailed:
                return "Falha na autenticação"
            case .rateLimitExceeded:
                return "Limite de requisições excedido"
            case .serverError(let code):
                return "Erro do servidor: \(code)"
            case .decodingError:
                return "Erro ao processar resposta"
            case .unknownError(let error):
                return "Erro desconhecido: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observar mudanças na conectividade
        networkManager.$isConnected
            .sink { [weak self] isConnected in
                if !isConnected {
                    self?.lastError = .networkUnavailable
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - OpenAI API
    
    func generateDiaryInsight(text: String) async throws -> DiaryInsight {
        guard !configManager.openAIAPIKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        
        let url = URL(string: "\(Endpoints.openAI)/chat/completions")!
        
        let requestBody = OpenAIRequest(
            model: configManager.openAIModel,
            messages: [
                OpenAIMessage(
                    role: "system",
                    content: "Você é um assistente especializado em saúde mental. Analise o texto do diário e forneça insights úteis e empáticos."
                ),
                OpenAIMessage(
                    role: "user",
                    content: "Analise este texto do diário e forneça insights sobre o estado emocional: \(text)"
                )
            ],
            maxTokens: 500,
            temperature: 0.7
        )
        
        let headers = [
            "Authorization": "Bearer \(configManager.openAIAPIKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            isLoading = true
            let response: OpenAIResponse = try await networkManager.post(
                url: url,
                body: requestBody,
                headers: headers,
                config: .critical
            )
            
            return DiaryInsight(
                text: response.choices.first?.message.content ?? "",
                sentiment: analyzeSentiment(from: response.choices.first?.message.content ?? ""),
                timestamp: Date()
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Stripe API
    
    func createPaymentIntent(amount: Int, currency: String = "brl") async throws -> PaymentIntentResponse {
        guard !configManager.stripePublishableKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        
        let url = URL(string: "\(Endpoints.stripe)/payment_intents")!
        
        let requestBody = StripePaymentIntentRequest(
            amount: amount,
            currency: currency,
            automaticPaymentMethods: StripeAutomaticPaymentMethods(enabled: true)
        )
        
        let headers = [
            "Authorization": "Bearer \(configManager.stripePublishableKey)",
            "Content-Type": "application/json"
        ]
        
        do {
            isLoading = true
            return try await networkManager.post(
                url: url,
                body: requestBody,
                headers: headers,
                config: .critical
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    func getCustomerSubscriptions(customerId: String) async throws -> StripeSubscriptionResponse {
        guard !configManager.stripePublishableKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        
        let url = URL(string: "\(Endpoints.stripe)/customers/\(customerId)/subscriptions")!
        
        let headers = [
            "Authorization": "Bearer \(configManager.stripePublishableKey)"
        ]
        
        do {
            isLoading = true
            return try await networkManager.get(
                url: url,
                headers: headers,
                config: .default
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Supabase API
    
    func saveUserData<T: Codable>(_ data: T, to table: String) async throws -> SupabaseResponse {
        guard !configManager.supabaseURL.isEmpty && !configManager.supabaseAnonKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        
        let url = URL(string: "\(Endpoints.supabase(environment: configManager.currentEnvironment))/\(table)")!
        
        let headers = [
            "apikey": configManager.supabaseAnonKey,
            "Authorization": "Bearer \(configManager.supabaseAnonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
        
        do {
            isLoading = true
            return try await networkManager.post(
                url: url,
                body: data,
                headers: headers,
                config: .default
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    func fetchUserData<T: Codable>(from table: String, userId: String, type: T.Type) async throws -> [T] {
        guard !configManager.supabaseURL.isEmpty && !configManager.supabaseAnonKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        
        let url = URL(string: "\(Endpoints.supabase(environment: configManager.currentEnvironment))/\(table)?user_id=eq.\(userId)")!
        
        let headers = [
            "apikey": configManager.supabaseAnonKey,
            "Authorization": "Bearer \(configManager.supabaseAnonKey)"
        ]
        
        do {
            isLoading = true
            return try await networkManager.get(
                url: url,
                headers: headers,
                config: .default
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - ManusPsiqueia Backend API
    
    func checkAPIHealth() async throws -> HealthCheckResponse {
        let url = URL(string: "\(Endpoints.manusAPI(environment: configManager.currentEnvironment))/health")!
        
        do {
            isLoading = true
            return try await networkManager.get(
                url: url,
                config: .fast
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    func syncUserProfile(_ profile: UserProfile) async throws -> UserProfileResponse {
        let url = URL(string: "\(Endpoints.manusAPI(environment: configManager.currentEnvironment))/users/profile")!
        
        do {
            isLoading = true
            return try await networkManager.post(
                url: url,
                body: profile,
                config: .default
            )
        } catch {
            lastError = mapError(error)
            throw lastError!
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Utility Methods
    
    private func mapError(_ error: Error) -> APIError {
        if let networkError = error as? NetworkManager.NetworkError {
            switch networkError {
            case .noInternetConnection:
                return .networkUnavailable
            case .unauthorized:
                return .authenticationFailed
            case .rateLimited:
                return .rateLimitExceeded
            case .serverError(let code):
                return .serverError(code)
            case .decodingError:
                return .decodingError
            default:
                return .unknownError(networkError)
            }
        }
        
        return .unknownError(error)
    }
    
    private func analyzeSentiment(from text: String) -> DiaryInsight.Sentiment {
        let lowercased = text.lowercased()
        
        let positiveWords = ["feliz", "alegre", "bem", "ótimo", "excelente", "maravilhoso", "positivo"]
        let negativeWords = ["triste", "deprimido", "mal", "ruim", "terrível", "horrível", "negativo"]
        
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }
    
    // MARK: - Validation Methods
    
    func validateAPIConfiguration() -> [String] {
        var errors: [String] = []
        
        if configManager.openAIAPIKey.isEmpty {
            errors.append("OpenAI API Key não configurada")
        }
        
        if configManager.stripePublishableKey.isEmpty {
            errors.append("Stripe Publishable Key não configurada")
        }
        
        if configManager.supabaseURL.isEmpty {
            errors.append("Supabase URL não configurada")
        }
        
        if configManager.supabaseAnonKey.isEmpty {
            errors.append("Supabase Anon Key não configurada")
        }
        
        return errors
    }
    
    func testAllAPIs() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Teste OpenAI
        do {
            _ = try await generateDiaryInsight(text: "Teste de conectividade")
            results["OpenAI"] = true
        } catch {
            results["OpenAI"] = false
        }
        
        // Teste Stripe
        do {
            _ = try await createPaymentIntent(amount: 100)
            results["Stripe"] = true
        } catch {
            results["Stripe"] = false
        }
        
        // Teste Supabase
        do {
            _ = try await fetchUserData(from: "test", userId: "test", type: String.self)
            results["Supabase"] = true
        } catch {
            results["Supabase"] = false
        }
        
        // Teste Backend
        do {
            _ = try await checkAPIHealth()
            results["Backend"] = true
        } catch {
            results["Backend"] = false
        }
        
        return results
    }
}

// MARK: - Data Models

// OpenAI Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// Stripe Models
struct StripePaymentIntentRequest: Codable {
    let amount: Int
    let currency: String
    let automaticPaymentMethods: StripeAutomaticPaymentMethods
    
    enum CodingKeys: String, CodingKey {
        case amount, currency
        case automaticPaymentMethods = "automatic_payment_methods"
    }
}

struct StripeAutomaticPaymentMethods: Codable {
    let enabled: Bool
}

struct PaymentIntentResponse: Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id, amount, currency, status
        case clientSecret = "client_secret"
    }
}

struct StripeSubscriptionResponse: Codable {
    let data: [StripeSubscription]
}

struct StripeSubscription: Codable {
    let id: String
    let status: String
    let currentPeriodEnd: Int
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case currentPeriodEnd = "current_period_end"
    }
}

// Supabase Models
struct SupabaseResponse: Codable {
    let id: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}

// Backend Models
struct HealthCheckResponse: Codable {
    let status: String
    let timestamp: String
    let version: String
}

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let preferences: [String: String]
}

struct UserProfileResponse: Codable {
    let id: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case updatedAt = "updated_at"
    }
}

// Diary Models
struct DiaryInsight: Codable {
    let text: String
    let sentiment: Sentiment
    let timestamp: Date
    
    enum Sentiment: String, Codable {
        case positive = "positive"
        case negative = "negative"
        case neutral = "neutral"
    }
}
