//
//  SubscriptionService.swift
//  ManusPsiqueia
//
//  Created by Thales Andrades on 2024
//  Copyright © 2024 ManusPsiqueia. All rights reserved.
//

import Foundation
import Stripe

/// Serviço de gerenciamento de assinaturas com integração Stripe
@MainActor
class SubscriptionService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    @Published var currentSubscription: StripeSubscription?
    @Published var availablePlans: [SubscriptionPlan] = []
    @Published var isLoading: Bool = false
    @Published var error: SubscriptionError?
    
    // MARK: - Private Properties
    private let stripeManager = StripeManager.shared
    private let securityManager = SecurityManager.shared
    private let auditLogger = AuditLogger()
    
    // MARK: - Enums
    enum SubscriptionError: LocalizedError {
        case planNotFound
        case subscriptionCreationFailed
        case subscriptionUpdateFailed
        case subscriptionCancellationFailed
        case paymentMethodRequired
        case insufficientPermissions
        
        var errorDescription: String? {
            switch self {
            case .planNotFound:
                return "Plano de assinatura não encontrado"
            case .subscriptionCreationFailed:
                return "Falha ao criar assinatura"
            case .subscriptionUpdateFailed:
                return "Falha ao atualizar assinatura"
            case .subscriptionCancellationFailed:
                return "Falha ao cancelar assinatura"
            case .paymentMethodRequired:
                return "Método de pagamento obrigatório"
            case .insufficientPermissions:
                return "Permissões insuficientes"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupSubscriptionPlans()
    }
    
    // MARK: - Setup Methods
    
    private func setupSubscriptionPlans() {
        availablePlans = [
            SubscriptionPlan(
                id: "starter",
                name: "Starter",
                description: "Ideal para psicólogos iniciantes",
                basePrice: 29.90,
                patientLimit: 10,
                features: [.basicAnalytics, .emailSupport],
                stripeProductId: "prod_starter",
                stripePriceId: "price_starter_monthly"
            ),
            SubscriptionPlan(
                id: "professional",
                name: "Professional",
                description: "Para psicólogos estabelecidos",
                basePrice: 59.90,
                patientLimit: 50,
                features: [.advancedAnalytics, .prioritySupport, .aiInsights],
                stripeProductId: "prod_professional",
                stripePriceId: "price_professional_monthly"
            ),
            SubscriptionPlan(
                id: "expert",
                name: "Expert",
                description: "Para clínicas e especialistas",
                basePrice: 99.90,
                patientLimit: 100,
                features: [.premiumAnalytics, .phoneSupport, .aiInsights, .customReports],
                stripeProductId: "prod_expert",
                stripePriceId: "price_expert_monthly"
            ),
            SubscriptionPlan(
                id: "enterprise",
                name: "Enterprise",
                description: "Para grandes organizações",
                basePrice: 199.90,
                patientLimit: -1, // Ilimitado
                features: [.allFeatures],
                stripeProductId: "prod_enterprise",
                stripePriceId: "price_enterprise_monthly"
            )
        ]
    }
    
    // MARK: - Subscription Management
    
    func createSubscription(planId: String, customerId: String, paymentMethodId: String) async throws -> StripeSubscription {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        guard let plan = availablePlans.first(where: { $0.id == planId }) else {
            throw SubscriptionError.planNotFound
        }
        
        do {
            // Anexar método de pagamento ao cliente
            try await stripeManager.attachPaymentMethod(paymentMethodId, to: customerId)
            
            // Criar assinatura no Stripe
            let subscription = try await createStripeSubscription(
                customerId: customerId,
                priceId: plan.stripePriceId,
                paymentMethodId: paymentMethodId
            )
            
            currentSubscription = subscription
            
            auditLogger.logSecurityEvent(.subscriptionCreated, 
                                        details: "Subscription created for plan: \(planId)")
            
            return subscription
            
        } catch {
            auditLogger.logSecurityEvent(.subscriptionCreationFailed, 
                                        details: "Failed to create subscription: \(error.localizedDescription)")
            throw SubscriptionError.subscriptionCreationFailed
        }
    }
    
    private func createStripeSubscription(customerId: String, priceId: String, paymentMethodId: String) async throws -> StripeSubscription {
        // Implementação da criação de assinatura via Stripe API
        let url = URL(string: "https://api.stripe.com/v1/subscriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(stripeManager.secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "customer": customerId,
            "items[0][price]": priceId,
            "default_payment_method": paymentMethodId,
            "expand[]": "latest_invoice.payment_intent"
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.subscriptionCreationFailed
        }
        
        let subscription = try JSONDecoder().decode(StripeSubscription.self, from: data)
        return subscription
    }
    
    // MARK: - Subscription Updates
    
    func updateSubscription(to newPlanId: String) async throws {
        guard let currentSub = currentSubscription else {
            throw SubscriptionError.subscriptionUpdateFailed
        }
        
        guard let newPlan = availablePlans.first(where: { $0.id == newPlanId }) else {
            throw SubscriptionError.planNotFound
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let updatedSubscription = try await updateStripeSubscription(
                subscriptionId: currentSub.id,
                newPriceId: newPlan.stripePriceId
            )
            
            currentSubscription = updatedSubscription
            
            auditLogger.logSecurityEvent(.subscriptionUpdated, 
                                        details: "Subscription updated to plan: \(newPlanId)")
            
        } catch {
            auditLogger.logSecurityEvent(.subscriptionUpdateFailed, 
                                        details: "Failed to update subscription: \(error.localizedDescription)")
            throw SubscriptionError.subscriptionUpdateFailed
        }
    }
    
    private func updateStripeSubscription(subscriptionId: String, newPriceId: String) async throws -> StripeSubscription {
        let url = URL(string: "https://api.stripe.com/v1/subscriptions/\(subscriptionId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(stripeManager.secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "items[0][price]": newPriceId,
            "proration_behavior": "create_prorations"
        ]
        
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.subscriptionUpdateFailed
        }
        
        let subscription = try JSONDecoder().decode(StripeSubscription.self, from: data)
        return subscription
    }
    
    // MARK: - Subscription Cancellation
    
    func cancelSubscription(immediately: Bool = false) async throws {
        guard let currentSub = currentSubscription else {
            return
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await cancelStripeSubscription(
                subscriptionId: currentSub.id,
                immediately: immediately
            )
            
            if immediately {
                currentSubscription = nil
            } else {
                // Marcar para cancelamento no final do período
                currentSubscription?.cancelAtPeriodEnd = true
            }
            
            auditLogger.logSecurityEvent(.subscriptionCancelled, 
                                        details: "Subscription cancelled (immediate: \(immediately))")
            
        } catch {
            auditLogger.logSecurityEvent(.subscriptionCancellationFailed, 
                                        details: "Failed to cancel subscription: \(error.localizedDescription)")
            throw SubscriptionError.subscriptionCancellationFailed
        }
    }
    
    private func cancelStripeSubscription(subscriptionId: String, immediately: Bool) async throws {
        let url = URL(string: "https://api.stripe.com/v1/subscriptions/\(subscriptionId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(stripeManager.secretKey)", forHTTPHeaderField: "Authorization")
        
        if !immediately {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "cancel_at_period_end=true".data(using: .utf8)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.subscriptionCancellationFailed
        }
    }
    
    // MARK: - Dynamic Pricing
    
    func calculateDynamicPrice(for planId: String, patientCount: Int, additionalFeatures: [PricingFeature] = []) -> Decimal {
        guard let basePlan = availablePlans.first(where: { $0.id == planId }) else {
            return 0
        }
        
        var totalPrice = basePlan.basePrice
        
        // Preço por paciente adicional
        if patientCount > basePlan.patientLimit && basePlan.patientLimit > 0 {
            let additionalPatients = patientCount - basePlan.patientLimit
            totalPrice += Decimal(additionalPatients) * 2.99 // R$ 2,99 por paciente adicional
        }
        
        // Preço por recursos adicionais
        for feature in additionalFeatures {
            if !basePlan.features.contains(feature) {
                totalPrice += feature.monthlyPrice
            }
        }
        
        // Aplicar desconto por volume
        if patientCount > 100 {
            totalPrice *= 0.9 // 10% de desconto
        } else if patientCount > 50 {
            totalPrice *= 0.95 // 5% de desconto
        }
        
        return totalPrice
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async throws {
        guard let currentSub = currentSubscription else {
            return
        }
        
        do {
            let updatedSubscription = try await fetchStripeSubscription(subscriptionId: currentSub.id)
            currentSubscription = updatedSubscription
            
        } catch {
            auditLogger.logSecurityEvent(.subscriptionStatusCheckFailed, 
                                        details: "Failed to check subscription status: \(error.localizedDescription)")
        }
    }
    
    private func fetchStripeSubscription(subscriptionId: String) async throws -> StripeSubscription {
        let url = URL(string: "https://api.stripe.com/v1/subscriptions/\(subscriptionId)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(stripeManager.secretKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.subscriptionUpdateFailed
        }
        
        let subscription = try JSONDecoder().decode(StripeSubscription.self, from: data)
        return subscription
    }
    
    // MARK: - Usage Tracking
    
    func trackUsage(patientCount: Int, feature: PricingFeature) async {
        // Implementar tracking de uso para billing baseado em uso
        auditLogger.logSecurityEvent(.usageTracked, 
                                    details: "Usage tracked - Patients: \(patientCount), Feature: \(feature)")
    }
}

// MARK: - Supporting Models

struct SubscriptionPlan: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let basePrice: Decimal
    let patientLimit: Int // -1 para ilimitado
    let features: [PricingFeature]
    let stripeProductId: String
    let stripePriceId: String
    
    var isUnlimited: Bool {
        return patientLimit == -1
    }
}

enum PricingFeature: String, CaseIterable, Codable {
    case basicAnalytics = "basic_analytics"
    case advancedAnalytics = "advanced_analytics"
    case premiumAnalytics = "premium_analytics"
    case aiInsights = "ai_insights"
    case customReports = "custom_reports"
    case emailSupport = "email_support"
    case prioritySupport = "priority_support"
    case phoneSupport = "phone_support"
    case allFeatures = "all_features"
    
    var displayName: String {
        switch self {
        case .basicAnalytics:
            return "Analytics Básico"
        case .advancedAnalytics:
            return "Analytics Avançado"
        case .premiumAnalytics:
            return "Analytics Premium"
        case .aiInsights:
            return "Insights de IA"
        case .customReports:
            return "Relatórios Personalizados"
        case .emailSupport:
            return "Suporte por Email"
        case .prioritySupport:
            return "Suporte Prioritário"
        case .phoneSupport:
            return "Suporte Telefônico"
        case .allFeatures:
            return "Todos os Recursos"
        }
    }
    
    var monthlyPrice: Decimal {
        switch self {
        case .basicAnalytics:
            return 9.90
        case .advancedAnalytics:
            return 19.90
        case .premiumAnalytics:
            return 29.90
        case .aiInsights:
            return 39.90
        case .customReports:
            return 14.90
        case .emailSupport:
            return 0 // Incluído
        case .prioritySupport:
            return 9.90
        case .phoneSupport:
            return 19.90
        case .allFeatures:
            return 0 // Calculado dinamicamente
        }
    }
}

// MARK: - Extensions

extension AuditLogger {
    enum SecurityEvent {
        case subscriptionCreated
        case subscriptionCreationFailed
        case subscriptionUpdated
        case subscriptionUpdateFailed
        case subscriptionCancelled
        case subscriptionCancellationFailed
        case subscriptionStatusCheckFailed
        case usageTracked
    }
}
