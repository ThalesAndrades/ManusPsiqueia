//
//  NetworkSecurityManager.swift
//  ManusPsiqueia
//
//  Created by Thales Andrades on 2024
//  Copyright © 2024 ManusPsiqueia. All rights reserved.
//

import Foundation
import Network
import Security

/// Gerenciador de segurança de rede com certificate pinning e proteção contra ataques
public class NetworkSecurityManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = NetworkSecurityManager()
    
    // MARK: - Published Properties
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var securityLevel: SecurityLevel = .high
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkSecurityMonitor")
    private let auditLogger = AuditLogger()
    
    // MARK: - Enums
    enum NetworkStatus {
        case connected
        case disconnected
        case unknown
    }
    
    enum SecurityLevel {
        case high
        case medium
        case low
        case compromised
    }
    
    enum NetworkSecurityError: LocalizedError {
        case certificatePinningFailed
        case untrustedNetwork
        case manInTheMiddleDetected
        case insecureConnection
        
        var errorDescription: String? {
            switch self {
            case .certificatePinningFailed:
                return "Falha na validação do certificado"
            case .untrustedNetwork:
                return "Rede não confiável detectada"
            case .manInTheMiddleDetected:
                return "Possível ataque man-in-the-middle detectado"
            case .insecureConnection:
                return "Conexão insegura"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        if path.status == .satisfied {
            networkStatus = .connected
            evaluateNetworkSecurity(path)
        } else {
            networkStatus = .disconnected
            securityLevel = .compromised
        }
        
        auditLogger.logSecurityEvent(.networkStatusChanged, 
                                    details: "Network status: \(networkStatus), Security level: \(securityLevel)")
    }
    
    private func evaluateNetworkSecurity(_ path: NWPath) {
        // Avaliar segurança da rede
        var securityScore = 100
        
        // Verificar se está usando WiFi público
        if path.usesInterfaceType(.wifi) {
            securityScore -= 20
        }
        
        // Verificar se está usando dados móveis
        if path.usesInterfaceType(.cellular) {
            securityScore += 10
        }
        
        // Verificar se há proxy
        if path.usesInterfaceType(.other) {
            securityScore -= 30
        }
        
        // Determinar nível de segurança
        switch securityScore {
        case 80...100:
            securityLevel = .high
        case 60...79:
            securityLevel = .medium
        case 40...59:
            securityLevel = .low
        default:
            securityLevel = .compromised
        }
    }
    
    // MARK: - Certificate Pinning
    
    func createSecureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        
        return session
    }
    
    private func validateCertificateChain(_ trust: SecTrust, for host: String) -> Bool {
        // Obter certificados pinned
        let pinnedCertificates = getPinnedCertificates()
        
        guard let pinnedCert = pinnedCertificates[host] else {
            auditLogger.logSecurityEvent(.certificatePinningFailed, 
                                        details: "No pinned certificate for host: \(host)")
            return false
        }
        
        // Validar cadeia de certificados
        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(trust, &result)
        
        guard status == errSecSuccess else {
            auditLogger.logSecurityEvent(.certificatePinningFailed, 
                                        details: "Certificate evaluation failed for host: \(host)")
            return false
        }
        
        // Verificar se o certificado está na cadeia
        let certificateCount = SecTrustGetCertificateCount(trust)
        
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(trust, i) {
                let certificateData = SecCertificateCopyData(certificate)
                let pinnedCertificateData = SecCertificateCopyData(pinnedCert)
                
                if CFEqual(certificateData, pinnedCertificateData) {
                    auditLogger.logSecurityEvent(.certificateValidated, 
                                                details: "Certificate validated for host: \(host)")
                    return true
                }
            }
        }
        
        auditLogger.logSecurityEvent(.certificatePinningFailed, 
                                    details: "Certificate pinning failed for host: \(host)")
        return false
    }
    
    private func getPinnedCertificates() -> [String: SecCertificate] {
        var certificates: [String: SecCertificate] = [:]
        
        // Certificados para APIs críticas
        let pinnedHosts = [
            "api.stripe.com": "stripe-api",
            "supabase.co": "supabase-api",
            "openai.com": "openai-api"
        ]
        
        for (host, certName) in pinnedHosts {
            if let certificate = loadCertificate(named: certName) {
                certificates[host] = certificate
            }
        }
        
        return certificates
    }
    
    private func loadCertificate(named name: String) -> SecCertificate? {
        guard let path = Bundle.main.path(forResource: name, ofType: "cer"),
              let certificateData = NSData(contentsOfFile: path) else {
            return nil
        }
        
        return SecCertificateCreateWithData(nil, certificateData)
    }
    
    // MARK: - Request Security
    
    func secureRequest(to url: URL, method: HTTPMethod = .GET, body: Data? = nil) async throws -> (Data, URLResponse) {
        // Verificar nível de segurança da rede
        guard securityLevel != .compromised else {
            throw NetworkSecurityError.untrustedNetwork
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Adicionar headers de segurança
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("ManusPsiqueia/1.0", forHTTPHeaderField: "User-Agent")
        
        // Usar sessão segura
        let session = createSecureURLSession()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Validar resposta
            try validateResponse(response, data: data)
            
            auditLogger.logSecurityEvent(.secureRequestCompleted, 
                                        details: "Secure request completed to: \(url.host ?? "unknown")")
            
            return (data, response)
        } catch {
            auditLogger.logSecurityEvent(.secureRequestFailed, 
                                        details: "Secure request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkSecurityError.insecureConnection
        }
        
        // Verificar status code
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkSecurityError.insecureConnection
        }
        
        // Verificar headers de segurança
        let securityHeaders = [
            "Strict-Transport-Security",
            "X-Content-Type-Options",
            "X-Frame-Options"
        ]
        
        for header in securityHeaders {
            if httpResponse.allHeaderFields[header] == nil {
                auditLogger.logSecurityEvent(.insecureResponse, 
                                            details: "Missing security header: \(header)")
            }
        }
    }
    
    // MARK: - Man-in-the-Middle Detection
    
    private func detectManInTheMiddle(_ challenge: URLAuthenticationChallenge) -> Bool {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return true // Suspeito se não há trust
        }
        
        // Verificar se o certificado mudou inesperadamente
        let host = challenge.protectionSpace.host
        
        // Em uma implementação real, você compararia com certificados conhecidos
        // e detectaria mudanças suspeitas
        
        return false // Não detectado neste exemplo
    }
}

// MARK: - URLSessionDelegate

extension NetworkSecurityManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge, 
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let host = challenge.protectionSpace.host
        
        // Detectar possível man-in-the-middle
        if detectManInTheMiddle(challenge) {
            auditLogger.logSecurityEvent(.manInTheMiddleDetected, 
                                        details: "Possible MITM attack detected for host: \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validar certificate pinning
        if let serverTrust = challenge.protectionSpace.serverTrust,
           validateCertificateChain(serverTrust, for: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            auditLogger.logSecurityEvent(.certificatePinningFailed, 
                                        details: "Certificate pinning failed for host: \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Supporting Types

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Extensions

extension AuditLogger {
    enum SecurityEvent {
        case networkStatusChanged
        case certificateValidated
        case certificatePinningFailed
        case secureRequestCompleted
        case secureRequestFailed
        case insecureResponse
        case manInTheMiddleDetected
    }
}
