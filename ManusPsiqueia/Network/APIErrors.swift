//
//  APIErrors.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation

// MARK: - Network Error

/// Enum centralizado para erros da camada de rede
/// Conforma com LocalizedError para fornecer mensagens de erro localizadas
enum NetworkError: Error, LocalizedError, Equatable {
    
    // MARK: - Cases
    
    /// URL inválida fornecida
    case invalidURL(String)
    
    /// Erro de conectividade/rede
    case noInternetConnection
    
    /// Resposta inválida do servidor
    case invalidResponse
    
    /// Nenhum dado retornado
    case noData
    
    /// Erro HTTP com código de status
    case httpError(statusCode: Int)
    
    /// Erro de decodificação de dados
    case decodingError(String)
    
    /// Falha na autenticação
    case unauthorized
    
    /// Limite de requisições excedido
    case rateLimited
    
    /// Timeout da requisição
    case timeout
    
    /// Erro desconhecido
    case unknown(Error)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL inválida: \(url)"
            
        case .noInternetConnection:
            return "Sem conexão com a internet. Verifique sua conectividade e tente novamente."
            
        case .invalidResponse:
            return "Resposta inválida do servidor. Tente novamente mais tarde."
            
        case .noData:
            return "Nenhum dado recebido do servidor."
            
        case .httpError(let statusCode):
            return httpErrorMessage(for: statusCode)
            
        case .decodingError(let details):
            return "Erro ao processar dados do servidor: \(details)"
            
        case .unauthorized:
            return "Falha na autenticação. Faça login novamente."
            
        case .rateLimited:
            return "Muitas requisições. Aguarde um momento e tente novamente."
            
        case .timeout:
            return "Tempo limite da requisição excedido. Tente novamente."
            
        case .unknown(let error):
            return "Erro inesperado: \(error.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "A URL fornecida não é válida"
            
        case .noInternetConnection:
            return "Dispositivo não conectado à internet"
            
        case .invalidResponse:
            return "Servidor retornou resposta em formato inesperado"
            
        case .noData:
            return "Servidor não retornou dados"
            
        case .httpError(let statusCode):
            return "Servidor retornou código de erro HTTP: \(statusCode)"
            
        case .decodingError:
            return "Falha ao decodificar resposta do servidor"
            
        case .unauthorized:
            return "Token de autenticação inválido ou expirado"
            
        case .rateLimited:
            return "Limite de requisições por minuto excedido"
            
        case .timeout:
            return "Servidor demorou muito para responder"
            
        case .unknown:
            return "Erro interno não identificado"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Verifique se a URL está correta"
            
        case .noInternetConnection:
            return "Conecte-se a uma rede Wi-Fi ou celular e tente novamente"
            
        case .invalidResponse:
            return "Aguarde alguns minutos e tente novamente"
            
        case .noData:
            return "Verifique se o serviço está funcionando e tente novamente"
            
        case .httpError(let statusCode):
            return httpRecoverySuggestion(for: statusCode)
            
        case .decodingError:
            return "Reporte este problema ao suporte técnico"
            
        case .unauthorized:
            return "Faça logout e login novamente"
            
        case .rateLimited:
            return "Aguarde 1 minuto e tente novamente"
            
        case .timeout:
            return "Verifique sua conexão e tente novamente"
            
        case .unknown:
            return "Reinicie o aplicativo e tente novamente"
        }
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
            return lhsURL == rhsURL
        case (.noInternetConnection, .noInternetConnection),
             (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.rateLimited, .rateLimited),
             (.timeout, .timeout):
            return true
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.decodingError(let lhsDetails), .decodingError(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func httpErrorMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Requisição inválida (400). Verifique os dados enviados."
        case 401:
            return "Não autorizado (401). Faça login novamente."
        case 403:
            return "Acesso negado (403). Você não tem permissão para esta ação."
        case 404:
            return "Recurso não encontrado (404). O conteúdo solicitado não existe."
        case 408:
            return "Tempo limite da requisição (408). Tente novamente."
        case 429:
            return "Muitas requisições (429). Aguarde um momento."
        case 500:
            return "Erro interno do servidor (500). Tente novamente mais tarde."
        case 502:
            return "Serviço temporariamente indisponível (502). Tente novamente."
        case 503:
            return "Serviço em manutenção (503). Tente novamente em alguns minutos."
        case 504:
            return "Timeout do servidor (504). Tente novamente."
        default:
            return "Erro HTTP \(statusCode). Contacte o suporte se o problema persistir."
        }
    }
    
    private func httpRecoverySuggestion(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Verifique se todos os campos obrigatórios foram preenchidos corretamente"
        case 401, 403:
            return "Faça logout e login novamente"
        case 404:
            return "Verifique se o recurso ainda existe ou reporte o problema"
        case 408, 504:
            return "Verifique sua conexão e tente novamente"
        case 429:
            return "Aguarde pelo menos 1 minuto antes de tentar novamente"
        case 500, 502, 503:
            return "O problema é temporário. Tente novamente em alguns minutos"
        default:
            return "Se o problema persistir, contacte o suporte técnico"
        }
    }
}

// MARK: - API Error Categories

/// Categorias de erro para facilitar o tratamento na UI
extension NetworkError {
    
    /// Indica se o erro é relacionado à conectividade
    var isConnectivityError: Bool {
        switch self {
        case .noInternetConnection, .timeout:
            return true
        default:
            return false
        }
    }
    
    /// Indica se o erro é relacionado à autenticação
    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized, .httpError(401), .httpError(403):
            return true
        default:
            return false
        }
    }
    
    /// Indica se o erro é temporário e pode ser resolvido tentando novamente
    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .timeout, .httpError(500), .httpError(502), .httpError(503), .httpError(504):
            return true
        default:
            return false
        }
    }
    
    /// Indica se o erro requer intervenção do usuário
    var requiresUserAction: Bool {
        switch self {
        case .unauthorized, .httpError(401), .httpError(403):
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Factory

/// Factory para criar erros NetworkError a partir de diferentes tipos de erro
extension NetworkError {
    
    /// Cria um NetworkError a partir de um URLError
    static func from(urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .badURL:
            return .invalidURL(urlError.localizedDescription)
        default:
            return .unknown(urlError)
        }
    }
    
    /// Cria um NetworkError a partir de um código de status HTTP
    static func from(httpStatusCode: Int) -> NetworkError {
        switch httpStatusCode {
        case 401:
            return .unauthorized
        case 429:
            return .rateLimited
        default:
            return .httpError(statusCode: httpStatusCode)
        }
    }
    
    /// Cria um NetworkError a partir de um erro de decodificação
    static func from(decodingError: DecodingError) -> NetworkError {
        let errorDescription: String
        switch decodingError {
        case .typeMismatch(let type, let context):
            errorDescription = "Tipo incompatível: \(type) em \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            errorDescription = "Valor não encontrado: \(type) em \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            errorDescription = "Chave não encontrada: \(key.stringValue) em \(context.debugDescription)"
        case .dataCorrupted(let context):
            errorDescription = "Dados corrompidos: \(context.debugDescription)"
        @unknown default:
            errorDescription = "Erro de decodificação desconhecido"
        }
        return .decodingError(errorDescription)
    }
}