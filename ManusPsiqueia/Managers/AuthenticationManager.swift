//
//  AuthenticationManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var authenticationError: NetworkError? = nil
    @Published var isLoading: Bool = false
    
    // Authentication state
    @Published var authenticationState: AuthenticationState = .loggedOut
    
    private let networkManager = NetworkManager.shared
    private let auditLogger = AuditLogger.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum AuthenticationState {
        case loggedOut
        case loggingIn
        case loggedIn
        case registering
        case error(String)
        case needsOnboarding
    }
    
    init() {
        checkStoredUser()
    }
    
    // MARK: - Private Methods
    private func checkStoredUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            self.authenticationState = .loggedIn
            auditLogger.log(event: .authenticationSuccess, details: ["user_id": user.id.uuidString], severity: .info)
        } else {
            self.authenticationState = .loggedOut
        }
    }
    
    // MARK: - Public Methods for New Navigation Pattern
    func checkAuthenticationState() async {
        // Check if user session is still valid
        if let user = currentUser {
            // Validate session with backend if needed
            await refreshAuthenticationState()
        }
    }
    
    func refreshAuthenticationState() async {
        // Refresh user data from backend
        guard let user = currentUser else { return }
        
        // For now, just update the state
        // In a real app, you'd validate the session with the backend
        await MainActor.run {
            self.isAuthenticated = true
            self.authenticationState = .loggedIn
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            await signIn(email: email, password: password)
            
            await MainActor.run {
                if isAuthenticated {
                    completion(true, nil)
                } else {
                    completion(false, authenticationError?.localizedDescription ?? "Erro desconhecido")
                }
            }
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        authenticationState = .loggingIn
        authenticationError = nil
        
        let loginPayload: [String: String] = ["email": email, "password": password]
        guard let body = try? JSONEncoder().encode(loginPayload) else {
            isLoading = false
            authenticationError = .invalidData
            authenticationState = .error("Dados inválidos")
            return
        }
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/auth/login") else {
            isLoading = false
            authenticationError = .invalidURL
            authenticationState = .error("URL inválida")
            return
        }
        
        do {
            let user: User = try await networkManager.request(
                url: url,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: body
            )
            
            self.currentUser = user
            self.isAuthenticated = true
            self.authenticationState = .loggedIn
            
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
            
            auditLogger.log(
                event: .authenticationSuccess,
                details: ["user_id": user.id.uuidString],
                severity: .info
            )
            
        } catch {
            self.authenticationError = error as? NetworkError ?? .unknown(error)
            self.authenticationState = .error(error.localizedDescription)
            auditLogger.logAuthenticationFailure(email: email, reason: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            await signUp(email: email, password: password)
            
            await MainActor.run {
                if isAuthenticated {
                    completion(true, nil)
                } else {
                    completion(false, authenticationError?.localizedDescription ?? "Erro desconhecido")
                }
            }
        }
    }
    
    @MainActor
    func signUp(email: String, password: String) async {
        isLoading = true
        authenticationState = .registering
        authenticationError = nil
        
        // Create a basic user object - in a real app, you'd collect more info
        let user = User(
            email: email,
            firstName: "Usuário",
            lastName: "Novo",
            userType: .patient // Default to patient, can be changed later
        )
        
        await register(user: user, password: password)
    }
    
    @MainActor
    func register(user: User, password: String) async {
        isLoading = true
        authenticationState = .registering
        authenticationError = nil
        
        // Create registration payload
        var registerPayload: [String: Any] = [
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "userType": user.userType.rawValue,
            "password": password
        ]
        
        if let phone = user.phone {
            registerPayload["phone"] = phone
        }
        
        if let dateOfBirth = user.dateOfBirth {
            registerPayload["dateOfBirth"] = ISO8601DateFormatter().string(from: dateOfBirth)
        }
        
        guard let body = try? JSONSerialization.data(withJSONObject: registerPayload) else {
            isLoading = false
            authenticationError = .invalidData
            authenticationState = .error("Dados inválidos")
            return
        }
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/auth/register") else {
            isLoading = false
            authenticationError = .invalidURL
            authenticationState = .error("URL inválida")
            return
        }
        
        do {
            let registeredUser: User = try await networkManager.request(
                url: url,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: body
            )
            
            self.currentUser = registeredUser
            self.isAuthenticated = true
            self.authenticationState = .loggedIn
            
            if let encoded = try? JSONEncoder().encode(registeredUser) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
            
            auditLogger.log(
                event: .authenticationSuccess,
                details: [
                    "user_id": registeredUser.id.uuidString,
                    "user_type": registeredUser.userType.rawValue
                ],
                severity: .info
            )
            
        } catch {
            self.authenticationError = error as? NetworkError ?? .unknown(error)
            self.authenticationState = .error(error.localizedDescription)
            auditLogger.logAuthenticationFailure(email: user.email, reason: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        Task {
            await signOutAsync()
        }
    }
    
    @MainActor
    func signOutAsync() async {
        isAuthenticated = false
        currentUser = nil
        authenticationState = .loggedOut
        authenticationError = nil
        
        UserDefaults.standard.removeObject(forKey: "currentUser")
        auditLogger.log(event: .logout, severity: .info)
        
        // Clear any other stored data
        UserDefaults.standard.removeObject(forKey: "hasShownOnboarding")
        
        // Give haptic feedback
        DesignSystem.Haptics.medium()
    }
    
    // MARK: - Profile Management
    func updateProfile(user: User) {
        Task {
            await updateProfileAsync(user: user)
        }
    }
    
    @MainActor
    func updateProfileAsync(user: User) async {
        self.currentUser = user
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        
        auditLogger.log(
            event: .profileUpdate,
            details: ["user_id": user.id.uuidString],
            severity: .info
        )
    }
    
    // MARK: - Password Reset
    @MainActor
    func requestPasswordReset(email: String) async -> Bool {
        isLoading = true
        authenticationError = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "https://api.manuspsiqueia.com/auth/password-reset") else {
            authenticationError = .invalidURL
            return false
        }
        
        let payload = ["email": email]
        guard let body = try? JSONEncoder().encode(payload) else {
            authenticationError = .invalidData
            return false
        }
        
        do {
            let _: [String: String] = try await networkManager.request(
                url: url,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: body
            )
            
            auditLogger.log(
                event: .passwordResetRequest,
                details: ["email": email],
                severity: .info
            )
            
            return true
            
        } catch {
            self.authenticationError = error as? NetworkError ?? .unknown(error)
            return false
        }
    }
    
    // MARK: - User Type Management
    func canSwitchUserType() -> Bool {
        // Allow switching if user hasn't been fully onboarded
        return currentUser?.userType == .patient // For example
    }
    
    @MainActor
    func switchUserType(to newType: UserType) async {
        guard let user = currentUser, canSwitchUserType() else { return }
        
        let updatedUser = User(
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            userType: newType,
            profileImageURL: user.profileImageURL,
            phone: user.phone,
            dateOfBirth: user.dateOfBirth,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        await updateProfileAsync(user: updatedUser)
    }
    
    // MARK: - Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    // MARK: - Computed Properties
    var isLoggedIn: Bool {
        return isAuthenticated && currentUser != nil
    }
    
    var userDisplayName: String {
        return currentUser?.fullName ?? "Usuário"
    }
    
    var userInitials: String {
        return currentUser?.initials ?? "U"
    }
}

// MARK: - NetworkManager Extension for Type-Safe Requests
extension NetworkManager {
    func request<T: Codable>(
        url: URL,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> T {
        // Implementation would depend on your existing NetworkManager
        // This is a placeholder for type-safe async requests
        
        let data = try await performRequest(url: url, method: method, headers: headers, body: body)
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    private func performRequest(
        url: URL,
        method: String,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
}

