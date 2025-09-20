//
//  NetworkManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import Combine

/// Gerenciador de rede para todas as requisições HTTP/HTTPS do aplicativo.
/// Integra Certificate Pinning para segurança avançada e utiliza Combine para reatividade.
final class NetworkManager: NSObject, URLSessionDelegate {
    
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let certificatePinningManager = CertificatePinningManager.shared
    private let auditLogger = AuditLogger.shared
    private let securityConfig = SecurityConfiguration()
    
    private override init() {
        let configuration = URLSessionConfiguration.default
        
        // Se o Certificate Pinning estiver habilitado, usamos o delegate para validação
        if securityConfig.enableStrictPinning {
            self.session = URLSession(configuration: configuration, delegate: certificatePinningManager, delegateQueue: nil)
        } else {
            self.session = URLSession(configuration: configuration)
        }
        super.init()
    }
    
    /// Realiza uma requisição de rede genérica com Combine.
    /// - Parameters:
    ///   - url: URL do endpoint.
    ///   - method: Método HTTP (GET, POST, etc.).
    ///   - headers: Cabeçalhos da requisição.
    ///   - body: Corpo da requisição (para POST/PUT).
    /// - Returns: Um Publisher que emite Data ou NetworkError.
    func request(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil
    ) -> AnyPublisher<Data, NetworkError> {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        auditLogger.log(
            event: .networkRequest,
            details: ["url": url.absoluteString, "method": method],
            severity: .info
        )
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.auditLogger.log(
                        event: .networkRequestFailed,
                        details: ["url": url.absoluteString, "reason": "invalid_response"],
                        severity: .critical
                    )
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.auditLogger.log(
                        event: .networkRequestFailed,
                        details: ["url": url.absoluteString, "status_code": httpResponse.statusCode],
                        severity: .critical
                    )
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
                
                self.auditLogger.log(
                    event: .networkRequestSuccess,
                    details: ["url": url.absoluteString, "status_code": httpResponse.statusCode],
                    severity: .info
                )
                return data
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                self.auditLogger.log(
                    event: .networkRequestFailed,
                    details: ["url": url.absoluteString, "error": error.localizedDescription],
                    severity: .critical
                )
                return NetworkError.unknown(error)
            }
            .eraseToAnyPublisher()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case noData // This case might be less relevant with dataTaskPublisher, but kept for consistency
    case httpError(statusCode: Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Resposta inválida do servidor."
        case .noData: return "Nenhum dado recebido do servidor."
        case .httpError(let statusCode): return "Erro HTTP: Código \(statusCode)"
        case .unknown(let error): return "Ocorreu um erro desconhecido: \(error.localizedDescription)"
        }
    }
}

