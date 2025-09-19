//
//  Subscription.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Model
struct Subscription: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let planType: SubscriptionPlan
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    let stripeSubscriptionId: String?
    let stripeCustomerId: String?
    let lastPaymentDate: Date?
    let nextPaymentDate: Date?
    let paymentMethod: PaymentMethod?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        planType: SubscriptionPlan,
        status: SubscriptionStatus = .active,
        startDate: Date = Date(),
        endDate: Date? = nil,
        autoRenew: Bool = true,
        stripeSubscriptionId: String? = nil,
        stripeCustomerId: String? = nil,
        lastPaymentDate: Date? = nil,
        nextPaymentDate: Date? = nil,
        paymentMethod: PaymentMethod? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.planType = planType
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.autoRenew = autoRenew
        self.stripeSubscriptionId = stripeSubscriptionId
        self.stripeCustomerId = stripeCustomerId
        self.lastPaymentDate = lastPaymentDate
        self.nextPaymentDate = nextPaymentDate
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isActive: Bool {
        return status == .active && (endDate == nil || endDate! > Date())
    }
    
    var daysUntilExpiration: Int? {
        guard let endDate = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
    
    var formattedNextPaymentDate: String {
        guard let nextPaymentDate = nextPaymentDate else { return "Não definido" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: nextPaymentDate)
    }
    
    var renewalWarning: String? {
        guard let days = daysUntilExpiration else { return nil }
        
        if days <= 0 {
            return "Assinatura expirada"
        } else if days <= 3 {
            return "Expira em \(days) dia\(days == 1 ? "" : "s")"
        } else if days <= 7 {
            return "Expira em \(days) dias"
        }
        
        return nil
    }
}

// MARK: - Subscription Plan
enum SubscriptionPlan: String, CaseIterable, Codable {
    case psychologistMonthly = "psychologist_monthly"
    case psychologistYearly = "psychologist_yearly"
    
    var displayName: String {
        switch self {
        case .psychologistMonthly:
            return "Psicólogo - Mensal"
        case .psychologistYearly:
            return "Psicólogo - Anual"
        }
    }
    
    var description: String {
        switch self {
        case .psychologistMonthly:
            return "Acesso completo à plataforma por 1 mês"
        case .psychologistYearly:
            return "Acesso completo à plataforma por 1 ano com desconto"
        }
    }
    
    var price: Decimal {
        switch self {
        case .psychologistMonthly:
            return 89.90
        case .psychologistYearly:
            return 899.00 // 10 meses pelo preço de 12
        }
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: price as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var monthlyEquivalent: String {
        switch self {
        case .psychologistMonthly:
            return formattedPrice
        case .psychologistYearly:
            let monthlyPrice = price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "pt_BR")
            return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? "R$ 0,00"
        }
    }
    
    var duration: String {
        switch self {
        case .psychologistMonthly:
            return "1 mês"
        case .psychologistYearly:
            return "12 meses"
        }
    }
    
    var savings: String? {
        switch self {
        case .psychologistMonthly:
            return nil
        case .psychologistYearly:
            return "Economize 2 meses"
        }
    }
    
    var features: [String] {
        return [
            "Acesso ilimitado à plataforma",
            "Gestão completa de pacientes",
            "Sistema de agendamento",
            "Chat seguro com pacientes",
            "Relatórios e análises",
            "Dashboard financeiro",
            "Suporte prioritário",
            "Integração com Stripe",
            "Backup automático de dados",
            "Conformidade com LGPD"
        ]
    }
    
    var color: Color {
        switch self {
        case .psychologistMonthly:
            return Color(red: 0.4, green: 0.2, blue: 0.8)
        case .psychologistYearly:
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        }
    }
    
    var icon: String {
        switch self {
        case .psychologistMonthly:
            return "calendar"
        case .psychologistYearly:
            return "calendar.badge.plus"
        }
    }
    
    var stripePriceId: String {
        switch self {
        case .psychologistMonthly:
            return "price_psychologist_monthly" // Será configurado no Stripe
        case .psychologistYearly:
            return "price_psychologist_yearly" // Será configurado no Stripe
        }
    }
    
    var storeKitProductId: String {
        switch self {
        case .psychologistMonthly:
            return "com.ailun.manuspsiqueia.psychologist.monthly"
        case .psychologistYearly:
            return "com.ailun.manuspsiqueia.psychologist.yearly"
        }
    }
}

// MARK: - Payment Method
struct PaymentMethod: Identifiable, Codable, Hashable {
    let id: String
    let type: PaymentMethodType
    let last4: String?
    let brand: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
    let stripePaymentMethodId: String?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        type: PaymentMethodType,
        last4: String? = nil,
        brand: String? = nil,
        expiryMonth: Int? = nil,
        expiryYear: Int? = nil,
        isDefault: Bool = false,
        stripePaymentMethodId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.last4 = last4
        self.brand = brand
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.isDefault = isDefault
        self.stripePaymentMethodId = stripePaymentMethodId
        self.createdAt = createdAt
    }
    
    var displayName: String {
        switch type {
        case .card:
            if let brand = brand, let last4 = last4 {
                return "\(brand.capitalized) •••• \(last4)"
            }
            return "Cartão de Crédito"
        case .pix:
            return "PIX"
        case .boleto:
            return "Boleto Bancário"
        case .applePay:
            return "Apple Pay"
        }
    }
    
    var icon: String {
        switch type {
        case .card:
            return "creditcard.fill"
        case .pix:
            return "qrcode"
        case .boleto:
            return "doc.text.fill"
        case .applePay:
            return "apple.logo"
        }
    }
    
    var formattedExpiry: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return String(format: "%02d/%02d", month, year % 100)
    }
}

enum PaymentMethodType: String, CaseIterable, Codable {
    case card = "card"
    case pix = "pix"
    case boleto = "boleto"
    case applePay = "apple_pay"
    
    var displayName: String {
        switch self {
        case .card:
            return "Cartão de Crédito"
        case .pix:
            return "PIX"
        case .boleto:
            return "Boleto Bancário"
        case .applePay:
            return "Apple Pay"
        }
    }
}

// MARK: - Subscription Transaction
struct SubscriptionTransaction: Identifiable, Codable {
    let id: UUID
    let subscriptionId: UUID
    let amount: Decimal
    let currency: String
    let status: TransactionStatus
    let paymentMethod: PaymentMethod
    let stripePaymentIntentId: String?
    let stripeChargeId: String?
    let failureReason: String?
    let processedAt: Date?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        subscriptionId: UUID,
        amount: Decimal,
        currency: String = "BRL",
        status: TransactionStatus,
        paymentMethod: PaymentMethod,
        stripePaymentIntentId: String? = nil,
        stripeChargeId: String? = nil,
        failureReason: String? = nil,
        processedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.amount = amount
        self.currency = currency
        self.status = status
        self.paymentMethod = paymentMethod
        self.stripePaymentIntentId = stripePaymentIntentId
        self.stripeChargeId = stripeChargeId
        self.failureReason = failureReason
        self.processedAt = processedAt
        self.createdAt = createdAt
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedDate: String {
        let date = processedAt ?? createdAt
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
}

enum TransactionStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case succeeded = "succeeded"
    case failed = "failed"
    case canceled = "canceled"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .processing:
            return "Processando"
        case .succeeded:
            return "Sucesso"
        case .failed:
            return "Falhou"
        case .canceled:
            return "Cancelado"
        case .refunded:
            return "Reembolsado"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .succeeded:
            return .green
        case .failed:
            return .red
        case .canceled:
            return .gray
        case .refunded:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .processing:
            return "arrow.clockwise"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .canceled:
            return "minus.circle.fill"
        case .refunded:
            return "arrow.uturn.left.circle.fill"
        }
    }
}

// MARK: - Subscription Extensions
extension Subscription {
    static let mockActive = Subscription(
        userId: UUID(),
        planType: .psychologistMonthly,
        status: .active,
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        stripeSubscriptionId: "sub_1234567890",
        stripeCustomerId: "cus_1234567890",
        lastPaymentDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
        nextPaymentDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
    )
    
    static let mockExpiring = Subscription(
        userId: UUID(),
        planType: .psychologistMonthly,
        status: .active,
        startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
        stripeSubscriptionId: "sub_0987654321",
        stripeCustomerId: "cus_0987654321",
        lastPaymentDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
        nextPaymentDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
    )
}

extension PaymentMethod {
    static let mockCard = PaymentMethod(
        type: .card,
        last4: "4242",
        brand: "visa",
        expiryMonth: 12,
        expiryYear: 2025,
        isDefault: true,
        stripePaymentMethodId: "pm_1234567890"
    )
    
    static let mockPix = PaymentMethod(
        type: .pix,
        isDefault: false
    )
}

extension SubscriptionTransaction {
    static let mockSucceeded = SubscriptionTransaction(
        subscriptionId: UUID(),
        amount: 89.90,
        status: .succeeded,
        paymentMethod: .mockCard,
        stripePaymentIntentId: "pi_1234567890",
        stripeChargeId: "ch_1234567890",
        processedAt: Date()
    )
    
    static let mockFailed = SubscriptionTransaction(
        subscriptionId: UUID(),
        amount: 89.90,
        status: .failed,
        paymentMethod: .mockCard,
        stripePaymentIntentId: "pi_0987654321",
        failureReason: "Cartão recusado"
    )
}
