//
//  AuthenticationManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import Combine

enum UserType: String, Codable {
    case psychologist
    case patient
}

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let userType: UserType
    var name: String?
    var profilePictureURL: URL?
    var isActive: Bool = true
    var isPremium: Bool = false
    var stripeCustomerId: String?
    var currentSubscriptionId: String?
    var authToken: String? // Adicionado para armazenar o token de autenticação
}

final class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var authenticationError: NetworkError? // Para erros de rede/autenticação
    
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            auditLogger.log(event: .authenticationSuccess, details: ["user_id": user.id.uuidString], severity: .info)
        }
    }
    
    func login(email: String, password: String) {
        let loginPayload: [String: String] = ["email": email, "password": password]
        guard let body = try? JSONEncoder().encode(loginPayload) else { return }
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/auth/login") else { return }
        
        networkManager.request(url: url, method: "POST", headers: ["Content-Type": "application/json"], body: body)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): 
                    self.authenticationError = error as? NetworkError ?? .unknown(error)
                    self.auditLogger.logAuthenticationFailure(email: email, reason: error.localizedDescription)
                case .finished: break
                }
            }, receiveValue: { user in
                self.currentUser = user
                self.isAuthenticated = true
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
                self.auditLogger.log(event: .authenticationSuccess, details: ["user_id": user.id.uuidString], severity: .info)
            })
            .store(in: &cancellables)
    }
    
    func register(user: User, password: String) {
        var registerPayload = user
        // Adicionar senha ao payload, se necessário, ou enviar separadamente
        // Para simplificar, assumimos que a senha é tratada no backend ou adicionada aqui
        // Ex: registerPayload["password"] = password // Se User fosse um dicionário ou tivesse um setter para senha
        
        guard let body = try? JSONEncoder().encode(registerPayload) else { return }
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/auth/register") else { return }
        
        networkManager.request(url: url, method: "POST", headers: ["Content-Type": "application/json"], body: body)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.authenticationError = error as? NetworkError ?? .unknown(error)
                    self.auditLogger.logAuthenticationFailure(email: user.email, reason: error.localizedDescription)
                case .finished: break
                }
            }, receiveValue: { registeredUser in
                self.currentUser = registeredUser
                self.isAuthenticated = true
                if let encoded = try? JSONEncoder().encode(registeredUser) {
                    UserDefaults.standard.set(encoded, forKey: "currentUser")
                }
                self.auditLogger.log(event: .authenticationSuccess, details: ["user_id": registeredUser.id.uuidString, "user_type": registeredUser.userType.rawValue], severity: .info)
            })
            .store(in: &cancellables)
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
        auditLogger.log(event: .logout, severity: .info)
        // Limpar tokens, sessões, etc. no backend se necessário
    }
    
    func updateProfile(user: User) {
        self.currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        auditLogger.log(event: .profileUpdate, details: ["user_id": user.id.uuidString], severity: .info)
    }
}

extension AuditLogger {
    func logAuthenticationFailure(email: String, reason: String) {
        log(event: .authenticationFailure, details: ["email": email, "reason": reason], severity: .warning)
    }
}

extension SecurityEvent {
    case authenticationSuccess
    case authenticationFailure
    case logout
    case profileUpdate
}

