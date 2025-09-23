//
//  Payment.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Simple Payment Model (for testing compatibility)
struct Payment: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let amount: Double
    let currency: String
    let date: Date
    var status: PaymentStatus
    
    init(id: String, userId: String, amount: Double, currency: String, date: Date, status: PaymentStatus) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.date = date
        self.status = status
    }
}

// MARK: - Payment Status
enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case succeeded = "succeeded"
    case failed = "failed"
    case canceled = "canceled"
    case refunded = "refunded"
    case partiallyRefunded = "partially_refunded"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendente"
        case .processing: return "Processando"
        case .succeeded: return "Pago"
        case .failed: return "Falhou"
        case .canceled: return "Cancelado"
        case .refunded: return "Reembolsado"
        case .partiallyRefunded: return "Parcialmente Reembolsado"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .succeeded: return .green
        case .failed, .canceled: return .red
        case .refunded, .partiallyRefunded: return .purple
        }
    }
}

// MARK: - Payment Method Type
enum PaymentMethodType: String, CaseIterable, Codable {
    case card = "card"
    case pix = "pix"
    case boleto = "boleto"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    
    var displayName: String {
        switch self {
        case .card: return "Cartão"
        case .pix: return "PIX"
        case .boleto: return "Boleto"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        }
    }
    
    var icon: String {
        switch self {
        case .card: return "creditcard"
        case .pix: return "qrcode"
        case .boleto: return "doc.text"
        case .applePay: return "applelogo"
        case .googlePay: return "g.circle"
        }
    }
}

// MARK: - Billing Period
enum BillingPeriod: String, CaseIterable, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiannual = "semiannual"
    case annual = "annual"
    case oneTime = "one_time"
    
    var displayName: String {
        switch self {
        case .monthly: return "Mensal"
        case .quarterly: return "Trimestral"
        case .semiannual: return "Semestral"
        case .annual: return "Anual"
        case .oneTime: return "Pagamento Único"
        }
    }
    
    var months: Int {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .semiannual: return 6
        case .annual: return 12
        case .oneTime: return 0
        }
    }
}

// MARK: - Patient Payment Model
struct PatientPayment: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let psychologistId: UUID
    let amount: Decimal
    let currency: String
    let status: PaymentStatus
    let paymentMethodType: PaymentMethodType
    let billingPeriod: BillingPeriod
    let dueDate: Date
    let paidDate: Date?
    let description: String
    
    // Stripe Integration
    let stripePaymentIntentId: String?
    let stripeChargeId: String?
    let stripeCustomerId: String?
    let stripeSubscriptionId: String?
    
    // Invoice & Receipt
    let invoiceNumber: String
    let invoiceURL: String?
    let receiptURL: String?
    
    // Failure Information
    let failureReason: String?
    let failureCode: String?
    
    // Metadata
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        patientId: UUID,
        psychologistId: UUID,
        amount: Decimal,
        currency: String = "BRL",
        status: PaymentStatus = .pending,
        paymentMethodType: PaymentMethodType,
        billingPeriod: BillingPeriod,
        dueDate: Date,
        paidDate: Date? = nil,
        description: String,
        stripePaymentIntentId: String? = nil,
        stripeChargeId: String? = nil,
        stripeCustomerId: String? = nil,
        stripeSubscriptionId: String? = nil,
        invoiceNumber: String? = nil,
        invoiceURL: String? = nil,
        receiptURL: String? = nil,
        failureReason: String? = nil,
        failureCode: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.psychologistId = psychologistId
        self.amount = amount
        self.currency = currency
        self.status = status
        self.paymentMethodType = paymentMethodType
        self.billingPeriod = billingPeriod
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.description = description
        self.stripePaymentIntentId = stripePaymentIntentId
        self.stripeChargeId = stripeChargeId
        self.stripeCustomerId = stripeCustomerId
        self.stripeSubscriptionId = stripeSubscriptionId
        self.invoiceNumber = invoiceNumber ?? "INV-\(Date().timeIntervalSince1970)"
        self.invoiceURL = invoiceURL
        self.receiptURL = receiptURL
        self.failureReason = failureReason
        self.failureCode = failureCode
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Payment Method Model
struct StripePaymentMethod: Identifiable, Codable, Hashable {
    let id: String
    let type: PaymentMethodType
    let customerId: String
    let isDefault: Bool
    let card: CardDetails?
    let pix: PixDetails?
    let createdAt: Date
    let lastUsed: Date?
    
    struct CardDetails: Codable, Hashable {
        let brand: String
        let last4: String
        let expMonth: Int
        let expYear: Int
        let country: String?
        let funding: String?
        
        var displayBrand: String {
            switch brand.lowercased() {
            case "visa": return "Visa"
            case "mastercard": return "Mastercard"
            case "amex": return "American Express"
            case "elo": return "Elo"
            case "hipercard": return "Hipercard"
            default: return brand.capitalized
            }
        }
        
        var isExpired: Bool {
            let now = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: now)
            let currentMonth = calendar.component(.month, from: now)
            
            if expYear < currentYear {
                return true
            } else if expYear == currentYear && expMonth < currentMonth {
                return true
            }
            return false
        }
    }
    
    struct PixDetails: Codable, Hashable {
        let bankName: String?
        let keyType: String?
    }
}

// MARK: - Payment Intent Model
struct PaymentIntent: Identifiable, Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: PaymentStatus
    let customerId: String
    let paymentMethodId: String?
    let description: String?
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Subscription Model
struct StripeSubscription: Identifiable, Codable {
    let id: String
    let customerId: String
    let status: SubscriptionStatus
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let canceledAt: Date?
    let priceId: String
    let quantity: Int
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
    
    enum SubscriptionStatus: String, Codable, CaseIterable {
        case incomplete = "incomplete"
        case incompleteExpired = "incomplete_expired"
        case trialing = "trialing"
        case active = "active"
        case pastDue = "past_due"
        case canceled = "canceled"
        case unpaid = "unpaid"
        
        var displayName: String {
            switch self {
            case .incomplete: return "Incompleta"
            case .incompleteExpired: return "Incompleta Expirada"
            case .trialing: return "Período de Teste"
            case .active: return "Ativa"
            case .pastDue: return "Em Atraso"
            case .canceled: return "Cancelada"
            case .unpaid: return "Não Paga"
            }
        }
        
        var color: Color {
            switch self {
            case .incomplete, .incompleteExpired: return .orange
            case .trialing: return .blue
            case .active: return .green
            case .pastDue, .unpaid: return .red
            case .canceled: return .gray
            }
        }
    }
}

// MARK: - Invoice Model
struct Invoice: Identifiable, Codable {
    let id: String
    let number: String
    let customerId: String
    let subscriptionId: String?
    let status: InvoiceStatus
    let amountDue: Int
    let amountPaid: Int
    let currency: String
    let dueDate: Date?
    let paidAt: Date?
    let hostedInvoiceUrl: String?
    let invoicePdf: String?
    let metadata: [String: String]
    let createdAt: Date
    
    enum InvoiceStatus: String, Codable, CaseIterable {
        case draft = "draft"
        case open = "open"
        case paid = "paid"
        case uncollectible = "uncollectible"
        case void = "void"
        
        var displayName: String {
            switch self {
            case .draft: return "Rascunho"
            case .open: return "Em Aberto"
            case .paid: return "Paga"
            case .uncollectible: return "Incobrável"
            case .void: return "Anulada"
            }
        }
        
        var color: Color {
            switch self {
            case .draft: return .gray
            case .open: return .orange
            case .paid: return .green
            case .uncollectible, .void: return .red
            }
        }
    }
}

// MARK: - Payment Analytics Model
struct PaymentAnalytics: Codable {
    let totalRevenue: Decimal
    let monthlyRevenue: Decimal
    let totalTransactions: Int
    let successfulTransactions: Int
    let failedTransactions: Int
    let averageTransactionValue: Decimal
    let topPaymentMethods: [PaymentMethodAnalytics]
    let revenueByMonth: [MonthlyRevenue]
    let churnRate: Double
    let mrr: Decimal // Monthly Recurring Revenue
    let arr: Decimal // Annual Recurring Revenue
    
    struct PaymentMethodAnalytics: Codable, Identifiable {
        let id = UUID()
        let type: PaymentMethodType
        let count: Int
        let percentage: Double
        let totalAmount: Decimal
    }
    
    struct MonthlyRevenue: Codable, Identifiable {
        let id = UUID()
        let month: String
        let year: Int
        let revenue: Decimal
        let transactionCount: Int
    }
    
    var successRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(successfulTransactions) / Double(totalTransactions) * 100
    }
    
    var failureRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(failedTransactions) / Double(totalTransactions) * 100
    }
}

// MARK: - Payment Configuration
struct PaymentConfiguration: Codable {
    let merchantName: String
    let supportedPaymentMethods: [PaymentMethodType]
    let defaultCurrency: String
    let minimumAmount: Int
    let maximumAmount: Int
    let allowSavePaymentMethods: Bool
    let requireBillingAddress: Bool
    let requireShippingAddress: Bool
    let automaticTax: Bool
    let webhookEndpoint: String?
    
    static let `default` = PaymentConfiguration(
        merchantName: "ManusPsiqueia",
        supportedPaymentMethods: [.card, .pix, .applePay],
        defaultCurrency: "BRL",
        minimumAmount: 1000, // R$ 10,00 em centavos
        maximumAmount: 100000000, // R$ 1.000.000,00 em centavos
        allowSavePaymentMethods: true,
        requireBillingAddress: false,
        requireShippingAddress: false,
        automaticTax: false,
        webhookEndpoint: nil
    )
}

// MARK: - Payment Extensions
extension PatientPayment {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var isOverdue: Bool {
        return status == .pending && Date() > dueDate
    }
    
    var daysSinceDue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    var statusIcon: String {
        switch status {
        case .pending: return "clock"
        case .processing: return "arrow.clockwise"
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .canceled: return "minus.circle.fill"
        case .refunded, .partiallyRefunded: return "arrow.uturn.left.circle.fill"
        }
    }
}

extension StripePaymentMethod {
    var displayName: String {
        switch type {
        case .card:
            if let card = card {
                return "\(card.displayBrand) •••• \(card.last4)"
            }
            return "Cartão"
        case .pix:
            return "PIX"
        case .boleto:
            return "Boleto Bancário"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        }
    }
}
