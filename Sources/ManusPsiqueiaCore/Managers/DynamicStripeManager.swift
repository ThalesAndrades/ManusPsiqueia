//
//  DynamicStripeManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class DynamicStripeManager: ObservableObject {
    @Published var isProcessingPayment = false
    @Published var currentSubscription: DynamicSubscription?
    @Published var paymentError: String?
    @Published var showingPaymentSheet = false
    
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = DynamicStripeManager()
    
    private init() {
        loadCurrentSubscription()
    }
    
    // MARK: - Subscription Management
    func createDynamicSubscription(
        psychologistId: String,
        patientCount: Int,
        selectedFeatures: [PlanFeature],
        calculator: DynamicPricingCalculator
    ) async throws -> DynamicSubscription {
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Calculate pricing
        let tier = calculator.findBestTier(for: patientCount)
        let totalPrice = calculator.calculateTotalPrice(
            patientCount: patientCount,
            selectedFeatures: selectedFeatures
        )
        
        // Create subscription object
        let subscription = DynamicSubscription(
            id: UUID().uuidString,
            psychologistId: psychologistId,
            tier: tier,
            patientCount: patientCount,
            selectedFeatures: selectedFeatures,
            monthlyPrice: totalPrice,
            status: .pending,
            createdAt: Date(),
            nextBillingDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        )
        
        // Create Stripe subscription
        try await createStripeSubscription(subscription)
        
        // Save locally
        currentSubscription = subscription
        saveSubscription(subscription)
        
        return subscription
    }
    
    func updateSubscription(
        newPatientCount: Int,
        newFeatures: [PlanFeature],
        calculator: DynamicPricingCalculator
    ) async throws {
        
        guard var subscription = currentSubscription else {
            throw StripeError.noActiveSubscription
        }
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Calculate new pricing
        let newTier = calculator.findBestTier(for: newPatientCount)
        let newTotalPrice = calculator.calculateTotalPrice(
            patientCount: newPatientCount,
            selectedFeatures: newFeatures
        )
        
        // Calculate prorated amount
        let proratedAmount = calculateProratedAmount(
            currentPrice: subscription.monthlyPrice,
            newPrice: newTotalPrice,
            billingDate: subscription.nextBillingDate
        )
        
        // Update subscription
        subscription.tier = newTier
        subscription.patientCount = newPatientCount
        subscription.selectedFeatures = newFeatures
        subscription.monthlyPrice = newTotalPrice
        subscription.lastModified = Date()
        
        // Update in Stripe
        try await updateStripeSubscription(subscription, proratedAmount: proratedAmount)
        
        // Save locally
        currentSubscription = subscription
        saveSubscription(subscription)
        
        // Notify about change
        NotificationCenter.default.post(
            name: NSNotification.Name("SubscriptionUpdated"),
            object: subscription
        )
    }
    
    func cancelSubscription() async throws {
        guard let subscription = currentSubscription else {
            throw StripeError.noActiveSubscription
        }
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // Cancel in Stripe
        try await cancelStripeSubscription(subscription.stripeSubscriptionId)
        
        // Update local subscription
        var updatedSubscription = subscription
        updatedSubscription.status = .cancelled
        updatedSubscription.cancelledAt = Date()
        
        currentSubscription = updatedSubscription
        saveSubscription(updatedSubscription)
        
        // Notify about cancellation
        NotificationCenter.default.post(
            name: NSNotification.Name("SubscriptionCancelled"),
            object: updatedSubscription
        )
    }
    
    // MARK: - Stripe Integration
    private func createStripeSubscription(_ subscription: DynamicSubscription) async throws {
        // Create customer if needed
        let customerId = try await createOrGetStripeCustomer(subscription.psychologistId)
        
        // Create price for the subscription
        let priceId = try await createDynamicPrice(
            amount: subscription.monthlyPrice,
            patientCount: subscription.patientCount,
            features: subscription.selectedFeatures
        )
        
        // Create subscription in Stripe
        let stripeSubscriptionId = try await createStripeSubscriptionWithPrice(
            customerId: customerId,
            priceId: priceId
        )
        
        // Update local subscription with Stripe IDs
        if var updatedSubscription = currentSubscription {
            updatedSubscription.stripeCustomerId = customerId
            updatedSubscription.stripeSubscriptionId = stripeSubscriptionId
            updatedSubscription.stripePriceId = priceId
            updatedSubscription.status = .active
            currentSubscription = updatedSubscription
        }
    }
    
    private func createOrGetStripeCustomer(_ psychologistId: String) async throws -> String {
        // Check if customer already exists
        if let existingCustomerId = UserDefaults.standard.string(forKey: "stripe_customer_id_\(psychologistId)") {
            return existingCustomerId
        }
        
        // Create new customer
        let requestBody: [String: Any] = [
            "metadata": [
                "psychologist_id": psychologistId,
                "platform": "ManusPsiqueia"
            ]
        ]
        
        let response = try await makeStripeAPIRequest(
            endpoint: "customers",
            method: "POST",
            body: requestBody
        )
        
        guard let customerId = response["id"] as? String else {
            throw StripeError.customerCreationFailed
        }
        
        // Save customer ID
        UserDefaults.standard.set(customerId, forKey: "stripe_customer_id_\(psychologistId)")
        
        return customerId
    }
    
    private func createDynamicPrice(
        amount: Int,
        patientCount: Int,
        features: [PlanFeature]
    ) async throws -> String {
        
        let featureNames = features.map { $0.name }.joined(separator: ", ")
        
        let requestBody: [String: Any] = [
            "unit_amount": amount,
            "currency": "brl",
            "recurring": [
                "interval": "month"
            ],
            "product_data": [
                "name": "ManusPsiqueia - Plano Personalizado",
                "description": "Plano para \(patientCount) pacientes com recursos: \(featureNames)",
                "metadata": [
                    "patient_count": patientCount,
                    "feature_count": features.count,
                    "plan_type": "dynamic"
                ]
            ],
            "metadata": [
                "patient_count": patientCount,
                "features": featureNames
            ]
        ]
        
        let response = try await makeStripeAPIRequest(
            endpoint: "prices",
            method: "POST",
            body: requestBody
        )
        
        guard let priceId = response["id"] as? String else {
            throw StripeError.priceCreationFailed
        }
        
        return priceId
    }
    
    private func createStripeSubscriptionWithPrice(
        customerId: String,
        priceId: String
    ) async throws -> String {
        
        let requestBody: [String: Any] = [
            "customer": customerId,
            "items": [
                [
                    "price": priceId
                ]
            ],
            "payment_behavior": "default_incomplete",
            "payment_settings": [
                "save_default_payment_method": "on_subscription"
            ],
            "expand": ["latest_invoice.payment_intent"],
            "metadata": [
                "platform": "ManusPsiqueia",
                "subscription_type": "dynamic"
            ]
        ]
        
        let response = try await makeStripeAPIRequest(
            endpoint: "subscriptions",
            method: "POST",
            body: requestBody
        )
        
        guard let subscriptionId = response["id"] as? String else {
            throw StripeError.subscriptionCreationFailed
        }
        
        return subscriptionId
    }
    
    private func updateStripeSubscription(
        _ subscription: DynamicSubscription,
        proratedAmount: Int
    ) async throws {
        
        // Create new price for updated subscription
        let newPriceId = try await createDynamicPrice(
            amount: subscription.monthlyPrice,
            patientCount: subscription.patientCount,
            features: subscription.selectedFeatures
        )
        
        // Update subscription items
        let requestBody: [String: Any] = [
            "items": [
                [
                    "id": subscription.stripeSubscriptionItemId ?? "",
                    "price": newPriceId
                ]
            ],
            "proration_behavior": "always_invoice",
            "metadata": [
                "updated_at": ISO8601DateFormatter().string(from: Date()),
                "patient_count": subscription.patientCount,
                "features": subscription.selectedFeatures.map { $0.name }.joined(separator: ", ")
            ]
        ]
        
        let _ = try await makeStripeAPIRequest(
            endpoint: "subscriptions/\(subscription.stripeSubscriptionId)",
            method: "POST",
            body: requestBody
        )
        
        // Update local subscription with new price ID
        if var updatedSubscription = currentSubscription {
            updatedSubscription.stripePriceId = newPriceId
            currentSubscription = updatedSubscription
        }
    }
    
    private func cancelStripeSubscription(_ subscriptionId: String) async throws {
        let requestBody: [String: Any] = [
            "cancel_at_period_end": true,
            "metadata": [
                "cancelled_at": ISO8601DateFormatter().string(from: Date()),
                "cancellation_reason": "user_requested"
            ]
        ]
        
        let _ = try await makeStripeAPIRequest(
            endpoint: "subscriptions/\(subscriptionId)",
            method: "POST",
            body: requestBody
        )
    }
    
    // MARK: - Billing and Invoicing
    func getUpcomingInvoice() async throws -> StripeInvoice {
        guard let subscription = currentSubscription else {
            throw StripeError.noActiveSubscription
        }
        
        let response = try await makeStripeAPIRequest(
            endpoint: "invoices/upcoming?customer=\(subscription.stripeCustomerId)",
            method: "GET",
            body: nil
        )
        
        return try parseStripeInvoice(response)
    }
    
    func getBillingHistory() async throws -> [StripeInvoice] {
        guard let subscription = currentSubscription else {
            throw StripeError.noActiveSubscription
        }
        
        let response = try await makeStripeAPIRequest(
            endpoint: "invoices?customer=\(subscription.stripeCustomerId)&limit=12",
            method: "GET",
            body: nil
        )
        
        guard let invoicesData = response["data"] as? [[String: Any]] else {
            throw StripeError.invalidResponse
        }
        
        return try invoicesData.map { try parseStripeInvoice($0) }
    }
    
    private func parseStripeInvoice(_ data: [String: Any]) throws -> StripeInvoice {
        guard let id = data["id"] as? String,
              let amount = data["amount_paid"] as? Int,
              let status = data["status"] as? String,
              let created = data["created"] as? TimeInterval else {
            throw StripeError.invalidResponse
        }
        
        return StripeInvoice(
            id: id,
            amount: amount,
            status: status,
            createdAt: Date(timeIntervalSince1970: created),
            pdfUrl: data["invoice_pdf"] as? String
        )
    }
    
    // MARK: - Usage-based Billing
    func reportUsage(patientCount: Int) async throws {
        guard let subscription = currentSubscription else { return }
        
        // Only report if patient count has changed significantly
        let threshold = max(1, subscription.patientCount / 10) // 10% threshold
        let difference = abs(patientCount - subscription.patientCount)
        
        if difference >= threshold {
            // Create usage record
            let requestBody: [String: Any] = [
                "quantity": patientCount,
                "timestamp": Int(Date().timeIntervalSince1970),
                "action": "set"
            ]
            
            let _ = try await makeStripeAPIRequest(
                endpoint: "subscription_items/\(subscription.stripeSubscriptionItemId ?? "")/usage_records",
                method: "POST",
                body: requestBody
            )
            
            // Update local subscription
            if var updatedSubscription = currentSubscription {
                updatedSubscription.patientCount = patientCount
                updatedSubscription.lastUsageReport = Date()
                currentSubscription = updatedSubscription
                saveSubscription(updatedSubscription)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func calculateProratedAmount(
        currentPrice: Int,
        newPrice: Int,
        billingDate: Date
    ) -> Int {
        let now = Date()
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: billingDate).day ?? 0
        
        let proratedFactor = Double(daysRemaining) / Double(daysInMonth)
        let priceDifference = newPrice - currentPrice
        
        return Int(Double(priceDifference) * proratedFactor)
    }
    
    private func makeStripeAPIRequest(
        endpoint: String,
        method: String,
        body: [String: Any]?
    ) async throws -> [String: Any] {
        
        guard let apiKey = getStripeSecretKey() else {
            throw StripeError.missingAPIKey
        }
        
        let url = URL(string: "https://api.stripe.com/v1/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try encodeFormData(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.networkError
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw StripeError.apiError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StripeError.invalidResponse
        }
        
        return json
    }
    
    private func encodeFormData(_ data: [String: Any]) throws -> Data {
        var components = URLComponents()
        components.queryItems = []
        
        for (key, value) in data {
            if let stringValue = value as? String {
                components.queryItems?.append(URLQueryItem(name: key, value: stringValue))
            } else if let intValue = value as? Int {
                components.queryItems?.append(URLQueryItem(name: key, value: String(intValue)))
            } else if let dictValue = value as? [String: Any] {
                for (subKey, subValue) in dictValue {
                    let fullKey = "\(key)[\(subKey)]"
                    if let stringSubValue = subValue as? String {
                        components.queryItems?.append(URLQueryItem(name: fullKey, value: stringSubValue))
                    } else if let intSubValue = subValue as? Int {
                        components.queryItems?.append(URLQueryItem(name: fullKey, value: String(intSubValue)))
                    }
                }
            } else if let arrayValue = value as? [[String: Any]] {
                for (index, item) in arrayValue.enumerated() {
                    for (subKey, subValue) in item {
                        let fullKey = "\(key)[\(index)][\(subKey)]"
                        if let stringSubValue = subValue as? String {
                            components.queryItems?.append(URLQueryItem(name: fullKey, value: stringSubValue))
                        } else if let intSubValue = subValue as? Int {
                            components.queryItems?.append(URLQueryItem(name: fullKey, value: String(intSubValue)))
                        }
                    }
                }
            }
        }
        
        return components.query?.data(using: .utf8) ?? Data()
    }
    
    private func getStripeSecretKey() -> String? {
        // In production, this should come from secure storage or environment variables
        return ProcessInfo.processInfo.environment["STRIPE_SECRET_KEY"]
    }
    
    // MARK: - Local Storage
    private func loadCurrentSubscription() {
        if let data = UserDefaults.standard.data(forKey: "current_subscription"),
           let subscription = try? JSONDecoder().decode(DynamicSubscription.self, from: data) {
            currentSubscription = subscription
        }
    }
    
    private func saveSubscription(_ subscription: DynamicSubscription) {
        if let data = try? JSONEncoder().encode(subscription) {
            UserDefaults.standard.set(data, forKey: "current_subscription")
        }
    }
    
    // MARK: - Analytics
    func getSubscriptionAnalytics() -> SubscriptionAnalytics {
        guard let subscription = currentSubscription else {
            return SubscriptionAnalytics(
                monthlyRevenue: 0,
                costPerPatient: 0,
                utilizationRate: 0,
                projectedAnnualCost: 0,
                savingsFromDynamicPricing: 0
            )
        }
        
        let costPerPatient = subscription.monthlyPrice / max(1, subscription.patientCount)
        let utilizationRate = Double(subscription.patientCount) / Double(subscription.tier.maxPatients ?? subscription.patientCount) * 100
        let projectedAnnualCost = subscription.monthlyPrice * 12
        
        // Calculate savings compared to fixed pricing
        let fixedPlanCost = 8990 // R$ 89.90 fixed plan
        let savingsFromDynamicPricing = max(0, fixedPlanCost - subscription.monthlyPrice)
        
        return SubscriptionAnalytics(
            monthlyRevenue: subscription.monthlyPrice,
            costPerPatient: costPerPatient,
            utilizationRate: utilizationRate,
            projectedAnnualCost: projectedAnnualCost,
            savingsFromDynamicPricing: savingsFromDynamicPricing
        )
    }
}

// MARK: - Supporting Models
public struct DynamicSubscription: Codable, Identifiable {
    let id: String
    let psychologistId: String
    var tier: PricingTier
    var patientCount: Int
    var selectedFeatures: [PlanFeature]
    var monthlyPrice: Int
    var status: SubscriptionStatus
    let createdAt: Date
    var lastModified: Date?
    var nextBillingDate: Date
    var cancelledAt: Date?
    var lastUsageReport: Date?
    
    // Stripe IDs
    var stripeCustomerId: String = ""
    var stripeSubscriptionId: String = ""
    var stripePriceId: String = ""
    var stripeSubscriptionItemId: String?
    
    var isActive: Bool {
        status == .active || status == .trialing
    }
    
    var daysUntilBilling: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextBillingDate).day ?? 0
    }
}

public enum SubscriptionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case active = "active"
    case trialing = "trialing"
    case pastDue = "past_due"
    case cancelled = "cancelled"
    case unpaid = "unpaid"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendente"
        case .active: return "Ativo"
        case .trialing: return "Período de Teste"
        case .pastDue: return "Em Atraso"
        case .cancelled: return "Cancelado"
        case .unpaid: return "Não Pago"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .active: return .green
        case .trialing: return .blue
        case .pastDue: return .red
        case .cancelled: return .gray
        case .unpaid: return .red
        }
    }
}

public struct StripeInvoice: Identifiable {
    let id: String
    let amount: Int
    let status: String
    let createdAt: Date
    let pdfUrl: String?
}

public struct SubscriptionAnalytics {
    let monthlyRevenue: Int
    let costPerPatient: Int
    let utilizationRate: Double
    let projectedAnnualCost: Int
    let savingsFromDynamicPricing: Int
}

public enum StripeError: Error, LocalizedError {
    case missingAPIKey
    case networkError
    case apiError(Int)
    case invalidResponse
    case noActiveSubscription
    case customerCreationFailed
    case priceCreationFailed
    case subscriptionCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Chave da API Stripe não encontrada"
        case .networkError:
            return "Erro de conexão com o Stripe"
        case .apiError(let code):
            return "Erro da API Stripe: \(code)"
        case .invalidResponse:
            return "Resposta inválida do Stripe"
        case .noActiveSubscription:
            return "Nenhuma assinatura ativa encontrada"
        case .customerCreationFailed:
            return "Falha ao criar cliente no Stripe"
        case .priceCreationFailed:
            return "Falha ao criar preço no Stripe"
        case .subscriptionCreationFailed:
            return "Falha ao criar assinatura no Stripe"
        }
    }
}
