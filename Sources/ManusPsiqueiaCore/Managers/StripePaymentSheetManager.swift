//
//  StripePaymentSheetManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Stripe
import StripePaymentSheet

@MainActor
public class StripePaymentSheetManager: ObservableObject {
    static let shared = StripePaymentSheetManager()
    
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    private let publishableKey = "pk_test_51234567890abcdef" // Replace with your actual key
    private let backendURL = "https://your-backend.com/api" // Replace with your backend
    
    // Backend model for PaymentSheet integration
    class BackendModel: ObservableObject {
        @Published var paymentSheet: PaymentSheet?
        @Published var paymentResult: PaymentSheetResult?
        
        var paymentIntentClientSecret: String?
        var customerEphemeralKeySecret: String?
        var customerId: String?
        var publishableKey: String?
        
        let backendCheckoutUrl: URL
        
        init(backendURL: String) {
            self.backendCheckoutUrl = URL(string: "\(backendURL)/checkout")!
        }
        
        func preparePaymentSheet(amount: Int, currency: String = "brl", userId: String) async {
            // Prepare request body
            let body = [
                "amount": amount,
                "currency": currency,
                "user_id": userId
            ] as [String : Any]
            
            var request = URLRequest(url: backendCheckoutUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                print("Error serializing request body: \(error)")
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                      let customerId = json["customer"] as? String,
                      let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                      let paymentIntentClientSecret = json["paymentIntent"] as? String,
                      let publishableKey = json["publishableKey"] as? String,
                      let self = self else {
                    print("Error preparing PaymentSheet: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Store values
                self.customerId = customerId
                self.customerEphemeralKeySecret = customerEphemeralKeySecret
                self.paymentIntentClientSecret = paymentIntentClientSecret
                self.publishableKey = publishableKey
                
                // Configure Stripe
                STPAPIClient.shared.publishableKey = publishableKey
                
                // Create PaymentSheet configuration
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "ManusPsiqueia - Saúde Mental"
                configuration.applePay = .init(
                    merchantId: "merchant.com.ailun.manuspsiqueia", // Use your actual merchant ID
                    merchantCountryCode: "BR"
                )
                configuration.customer = .init(
                    id: customerId, 
                    ephemeralKeySecret: customerEphemeralKeySecret
                )
                configuration.returnURL = "manuspsiqueia://stripe-redirect"
                configuration.allowsDelayedPaymentMethods = true
                
                // Customize appearance for mental health theme
                var appearance = PaymentSheet.Appearance()
                appearance.colors.primary = UIColor(red: 0.545, green: 0.373, blue: 0.965, alpha: 1.0) // Purple theme
                appearance.colors.background = UIColor.systemBackground
                appearance.colors.componentBackground = UIColor.secondarySystemBackground
                appearance.cornerRadius = 12.0
                appearance.borderWidth = 1.0
                appearance.font.base = UIFont.systemFont(ofSize: 16, weight: .regular)
                
                configuration.appearance = appearance
                
                DispatchQueue.main.async {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: paymentIntentClientSecret,
                        configuration: configuration
                    )
                }
            }
            
            task.resume()
        }
        
        func onCompletion(result: PaymentSheetResult) {
            self.paymentResult = result
            
            // Handle result
            switch result {
            case .completed:
                print("Payment completed successfully")
                // Reset for next payment
                self.paymentSheet = nil
            case .canceled:
                print("Payment was canceled")
            case .failed(let error):
                print("Payment failed: \(error.localizedDescription)")
            }
        }
    }
    
    @Published var backendModel: BackendModel
    
    private init() {
        self.backendModel = BackendModel(backendURL: backendURL)
        setupStripe()
    }
    
    private func setupStripe() {
        // Configure Stripe with your publishable key
        STPAPIClient.shared.publishableKey = publishableKey
    }
    
    // MARK: - Psychologist Subscription (R$ 89,90/month)
    func createPsychologistSubscription(userId: String, email: String) async throws -> SubscriptionResult {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Prepare PaymentSheet for subscription
            await backendModel.preparePaymentSheet(
                amount: 8990, // R$ 89,90 in cents
                currency: "brl",
                userId: userId
            )
            
            // Wait for PaymentSheet to be ready
            while backendModel.paymentSheet == nil {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            return SubscriptionResult(
                subscriptionId: UUID().uuidString,
                status: .active,
                amount: 8990,
                currency: "brl"
            )
        } catch {
            errorMessage = "Erro ao criar assinatura: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Patient Payment Processing
    func processPatientPayment(
        amount: Int,
        patientId: String,
        psychologistId: String
    ) async throws -> PaymentResult {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Prepare PaymentSheet for patient payment
            await backendModel.preparePaymentSheet(
                amount: amount,
                currency: "brl",
                userId: patientId
            )
            
            // Wait for PaymentSheet to be ready
            while backendModel.paymentSheet == nil {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            return PaymentResult(
                id: UUID().uuidString,
                amount: amount,
                currency: "brl",
                status: .pending,
                createdAt: Date()
            )
        } catch {
            errorMessage = "Erro ao processar pagamento: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - PaymentSheet Presentation
    func presentPaymentSheet() -> Bool {
        guard backendModel.paymentSheet != nil else {
            errorMessage = "PaymentSheet não está pronto"
            return false
        }
        return true
    }
    
    func handlePaymentResult(_ result: PaymentSheetResult) {
        backendModel.onCompletion(result: result)
        
        switch result {
        case .completed:
            errorMessage = nil
        case .canceled:
            errorMessage = "Pagamento cancelado pelo usuário"
        case .failed(let error):
            errorMessage = "Falha no pagamento: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Stripe Connect for Psychologists
    func setupPsychologistConnect(psychologistId: String, email: String) async throws -> ConnectAccountResult {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(backendURL)/connect/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "psychologist_id": psychologistId,
            "email": email,
            "type": "express",
            "country": "BR"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accountId = json["account_id"] as? String,
              let onboardingUrl = json["onboarding_url"] as? String else {
            throw StripeError.connectError("Falha ao criar conta Connect")
        }
        
        return ConnectAccountResult(
            accountId: accountId,
            onboardingUrl: onboardingUrl,
            status: .pending
        )
    }
    
    // MARK: - Withdrawal Management
    func createPayout(amount: Int, accountId: String) async throws -> PayoutResult {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(backendURL)/connect/payouts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "amount": amount - 250, // Subtract 2.5% fee (R$ 2,50 for every R$ 100)
            "currency": "brl",
            "account_id": accountId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payoutId = json["id"] as? String else {
            throw StripeError.paymentFailed("Falha ao criar saque")
        }
        
        return PayoutResult(
            id: payoutId,
            amount: amount - 250, // Net amount after fee
            fee: 250, // 2.5% fee
            currency: "brl",
            status: .pending,
            createdAt: Date()
        )
    }
    
    // MARK: - Financial Analytics
    func getPsychologistEarnings(accountId: String, period: EarningsPeriod) async throws -> EarningsReport {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(backendURL)/connect/earnings/\(accountId)")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "period", value: period.rawValue)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StripeError.networkError("Falha ao buscar relatório de ganhos")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(EarningsReport.self, from: data)
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        
        let value = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

// MARK: - Supporting Types
public enum StripeError: Error, LocalizedError {
    case invalidConfiguration
    case paymentFailed(String)
    case subscriptionError(String)
    case connectError(String)
    case networkError(String)
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Configuração do Stripe inválida"
        case .paymentFailed(let message):
            return "Falha no pagamento: \(message)"
        case .subscriptionError(let message):
            return "Erro na assinatura: \(message)"
        case .connectError(let message):
            return "Erro no Stripe Connect: \(message)"
        case .networkError(let message):
            return "Erro de rede: \(message)"
        case .notImplemented:
            return "Funcionalidade não implementada"
        }
    }
}

public struct PaymentResult {
    let id: String
    let amount: Int
    let currency: String
    let status: PaymentStatus
    let createdAt: Date
}

public struct SubscriptionResult {
    let subscriptionId: String
    let status: SubscriptionStatus
    let amount: Int
    let currency: String
}

public struct ConnectAccountResult {
    let accountId: String
    let onboardingUrl: String
    let status: ConnectStatus
}

public struct PayoutResult {
    let id: String
    let amount: Int
    let fee: Int
    let currency: String
    let status: PayoutStatus
    let createdAt: Date
}

public struct EarningsReport: Codable {
    let totalEarnings: Int
    let totalFees: Int
    let netEarnings: Int
    let transactionCount: Int
    let period: String
    let transactions: [EarningsTransaction]
}

public struct EarningsTransaction: Codable {
    let id: String
    let amount: Int
    let fee: Int
    let netAmount: Int
    let description: String
    let createdAt: Date
}

public enum PaymentStatus {
    case succeeded
    case failed
    case pending
    case canceled
}

public enum SubscriptionStatus {
    case active
    case canceled
    case pastDue
    case unpaid
}

public enum ConnectStatus {
    case pending
    case active
    case restricted
    case rejected
}

public enum PayoutStatus {
    case pending
    case paid
    case failed
    case canceled
}

public enum EarningsPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "Última semana"
        case .month: return "Último mês"
        case .quarter: return "Último trimestre"
        case .year: return "Último ano"
        }
    }
}
