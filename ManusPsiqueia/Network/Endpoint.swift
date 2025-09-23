//
//  Endpoint.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation

// MARK: - Endpoint Protocol

/// Protocol que define a estrutura de um endpoint de API
/// Permite maior flexibilidade e facilita a criação de mocks para testes
protocol Endpoint {
    /// Caminho do endpoint (ex: "/users", "/auth/login")
    var path: String { get }
    
    /// Método HTTP a ser utilizado
    var method: HTTPMethod { get }
    
    /// Parâmetros do corpo da requisição (para POST, PUT, PATCH)
    var parameters: [String: Any]? { get }
    
    /// Cabeçalhos customizados da requisição
    var headers: [String: String]? { get }
    
    /// URL base do serviço
    var baseURL: String { get }
    
    /// URL completa do endpoint
    var url: URL? { get }
}

// MARK: - HTTP Method

enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Default Endpoint Implementation

extension Endpoint {
    /// Implementação padrão para a URL completa
    var url: URL? {
        let fullPath = baseURL + path
        return URL(string: fullPath)
    }
    
    /// Headers padrão que podem ser sobrescritos
    var defaultHeaders: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    /// Combina headers padrão com headers customizados
    var allHeaders: [String: String] {
        var combinedHeaders = defaultHeaders
        headers?.forEach { key, value in
            combinedHeaders[key] = value
        }
        return combinedHeaders
    }
}

// MARK: - Concrete Endpoint Implementations

// MARK: OpenAI Endpoints
struct OpenAIEndpoint: Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let headers: [String: String]?
    
    var baseURL: String {
        "https://api.openai.com/v1"
    }
    
    static func chatCompletions(apiKey: String) -> OpenAIEndpoint {
        OpenAIEndpoint(
            path: "/chat/completions",
            method: .POST,
            parameters: nil,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ]
        )
    }
}

// MARK: Stripe Endpoints
struct StripeEndpoint: Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let headers: [String: String]?
    
    var baseURL: String {
        "https://api.stripe.com/v1"
    }
    
    static func paymentIntents(apiKey: String) -> StripeEndpoint {
        StripeEndpoint(
            path: "/payment_intents",
            method: .POST,
            parameters: nil,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ]
        )
    }
    
    static func customerSubscriptions(customerId: String, apiKey: String) -> StripeEndpoint {
        StripeEndpoint(
            path: "/customers/\(customerId)/subscriptions",
            method: .GET,
            parameters: nil,
            headers: [
                "Authorization": "Bearer \(apiKey)"
            ]
        )
    }
}

// MARK: Supabase Endpoints
struct SupabaseEndpoint: Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let headers: [String: String]?
    let environment: ConfigurationManager.Environment
    
    var baseURL: String {
        switch environment {
        case .development:
            return "https://dev-project.supabase.co/rest/v1"
        case .staging:
            return "https://staging-project.supabase.co/rest/v1"
        case .production:
            return "https://prod-project.supabase.co/rest/v1"
        }
    }
    
    static func table(_ tableName: String, environment: ConfigurationManager.Environment, anonKey: String) -> SupabaseEndpoint {
        SupabaseEndpoint(
            path: "/\(tableName)",
            method: .POST,
            parameters: nil,
            headers: [
                "apikey": anonKey,
                "Authorization": "Bearer \(anonKey)",
                "Prefer": "return=representation"
            ],
            environment: environment
        )
    }
    
    static func queryTable(_ tableName: String, userId: String, environment: ConfigurationManager.Environment, anonKey: String) -> SupabaseEndpoint {
        SupabaseEndpoint(
            path: "/\(tableName)?user_id=eq.\(userId)",
            method: .GET,
            parameters: nil,
            headers: [
                "apikey": anonKey,
                "Authorization": "Bearer \(anonKey)"
            ],
            environment: environment
        )
    }
}

// MARK: Backend Endpoints
struct ManusAPIEndpoint: Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let headers: [String: String]?
    let environment: ConfigurationManager.Environment
    
    var baseURL: String {
        switch environment {
        case .development:
            return "https://api-dev.manuspsiqueia.com/v1"
        case .staging:
            return "https://api-staging.manuspsiqueia.com/v1"
        case .production:
            return "https://api.manuspsiqueia.com/v1"
        }
    }
    
    static func health(environment: ConfigurationManager.Environment) -> ManusAPIEndpoint {
        ManusAPIEndpoint(
            path: "/health",
            method: .GET,
            parameters: nil,
            headers: nil,
            environment: environment
        )
    }
    
    static func userProfile(environment: ConfigurationManager.Environment) -> ManusAPIEndpoint {
        ManusAPIEndpoint(
            path: "/users/profile",
            method: .POST,
            parameters: nil,
            headers: nil,
            environment: environment
        )
    }
}

