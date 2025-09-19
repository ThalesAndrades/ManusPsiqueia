//
//  Payment.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Patient Payment Model
struct PatientPayment: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let psychologistId: UUID
    let amount: Decimal
    let status: PaymentStatus
    let paymentMethod: PaymentMethod
    let billingPeriod: BillingPeriod
    let dueDate: Date
    let paidDate: Date?
    let stripePaymentIntentId: String?
    let stripeChargeId: String?
    let invoiceURL: String?
    let failureReason: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        patientId: UUID,
        psychologistId: UUID,
        amount: Decimal,
        status: PaymentStatus = .pending,
        paymentMethod: PaymentMethod,
        billingPeriod: BillingPeriod,
        dueDate: Date,
        paidDate: Date? = nil,
        stripePaymentIntentId: String? = nil,
        stripeChargeId: String? = nil,
        invoiceURL: String? = nil,
        failureReason: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.psychologistId = psychologistId
        self.amount = amount
        self.status = status
        self.paymentMethod = paymentMethod
        self.billingPeriod = billingPeriod
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.stripePaymentIntentId = stripePaymentIntentId
        self.stripeChargeId = stripeChargeId
        self.invoiceURL = invoiceURL
        self.failureReason = failureReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: dueDate)
    }
    
    var formattedPaidDate: String? {
        guard let paidDate = paidDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: paidDate)
    }
    
    var isOverdue: Bool {
        return status != .succeeded && dueDate < Date()
    }
    
    var daysPastDue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    var daysUntilDue: Int {
        guard !isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var statusMessage: String {
        switch status {
        case .pending:
            if isOverdue {
                return "Vencido há \(daysPastDue) dia\(daysPastDue == 1 ? "" : "s")"
            } else if daysUntilDue <= 3 {
                return "Vence em \(daysUntilDue) dia\(daysUntilDue == 1 ? "" : "s")"
            } else {
                return "Pendente"
            }
        case .processing:
            return "Processando pagamento"
        case .succeeded:
            return "Pago em \(formattedPaidDate ?? "")"
        case .failed:
            return "Pagamento falhou"
        case .canceled:
            return "Cancelado"
        case .refunded:
            return "Reembolsado"
        }
    }
}

// MARK: - Billing Period
struct BillingPeriod: Codable, Hashable {
    let startDate: Date
    let endDate: Date
    let month: Int
    let year: Int
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: startDate)
        self.month = components.month ?? 1
        self.year = components.year ?? 2024
    }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM 'de' yyyy"
        return formatter.string(from: startDate).capitalized
    }
    
    var shortDisplayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMM/yyyy"
        return formatter.string(from: startDate)
    }
}

// MARK: - Psychologist Earnings
struct PsychologistEarnings: Identifiable, Codable {
    let id: UUID
    let psychologistId: UUID
    let totalEarnings: Decimal
    let availableForWithdrawal: Decimal
    let pendingEarnings: Decimal
    let totalWithdrawn: Decimal
    let platformFee: Decimal
    let netEarnings: Decimal
    let lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        psychologistId: UUID,
        totalEarnings: Decimal = 0,
        availableForWithdrawal: Decimal = 0,
        pendingEarnings: Decimal = 0,
        totalWithdrawn: Decimal = 0,
        platformFee: Decimal = 0,
        netEarnings: Decimal = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.psychologistId = psychologistId
        self.totalEarnings = totalEarnings
        self.availableForWithdrawal = availableForWithdrawal
        self.pendingEarnings = pendingEarnings
        self.totalWithdrawn = totalWithdrawn
        self.platformFee = platformFee
        self.netEarnings = netEarnings
        self.lastUpdated = lastUpdated
    }
    
    var formattedTotalEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: totalEarnings as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedAvailableForWithdrawal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: availableForWithdrawal as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedPendingEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: pendingEarnings as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedPlatformFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: platformFee as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var platformFeePercentage: Decimal {
        guard totalEarnings > 0 else { return 0 }
        return (platformFee / totalEarnings) * 100
    }
}

// MARK: - Withdrawal Request
struct WithdrawalRequest: Identifiable, Codable {
    let id: UUID
    let psychologistId: UUID
    let amount: Decimal
    let status: WithdrawalStatus
    let bankAccount: BankAccount
    let requestedAt: Date
    let processedAt: Date?
    let stripeTransferId: String?
    let failureReason: String?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        psychologistId: UUID,
        amount: Decimal,
        status: WithdrawalStatus = .pending,
        bankAccount: BankAccount,
        requestedAt: Date = Date(),
        processedAt: Date? = nil,
        stripeTransferId: String? = nil,
        failureReason: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.psychologistId = psychologistId
        self.amount = amount
        self.status = status
        self.bankAccount = bankAccount
        self.requestedAt = requestedAt
        self.processedAt = processedAt
        self.stripeTransferId = stripeTransferId
        self.failureReason = failureReason
        self.createdAt = createdAt
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedRequestedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: requestedAt)
    }
    
    var estimatedArrival: String {
        let businessDays = Calendar.current.date(byAdding: .day, value: 2, to: requestedAt) ?? requestedAt
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: businessDays)
    }
}

enum WithdrawalStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .processing:
            return "Processando"
        case .completed:
            return "Concluído"
        case .failed:
            return "Falhou"
        case .canceled:
            return "Cancelado"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .canceled:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .processing:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .canceled:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Bank Account
struct BankAccount: Identifiable, Codable, Hashable {
    let id: UUID
    let psychologistId: UUID
    let bankCode: String
    let bankName: String
    let accountType: AccountType
    let accountNumber: String
    let routingNumber: String // Agência
    let accountHolderName: String
    let accountHolderDocument: String // CPF/CNPJ
    let isDefault: Bool
    let isVerified: Bool
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        psychologistId: UUID,
        bankCode: String,
        bankName: String,
        accountType: AccountType,
        accountNumber: String,
        routingNumber: String,
        accountHolderName: String,
        accountHolderDocument: String,
        isDefault: Bool = false,
        isVerified: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.psychologistId = psychologistId
        self.bankCode = bankCode
        self.bankName = bankName
        self.accountType = accountType
        self.accountNumber = accountNumber
        self.routingNumber = routingNumber
        self.accountHolderName = accountHolderName
        self.accountHolderDocument = accountHolderDocument
        self.isDefault = isDefault
        self.isVerified = isVerified
        self.createdAt = createdAt
    }
    
    var displayName: String {
        return "\(bankName) - \(accountType.displayName) \(maskedAccountNumber)"
    }
    
    var maskedAccountNumber: String {
        guard accountNumber.count > 4 else { return accountNumber }
        let lastFour = String(accountNumber.suffix(4))
        let masked = String(repeating: "•", count: accountNumber.count - 4)
        return "\(masked)\(lastFour)"
    }
    
    var formattedDocument: String {
        let digits = accountHolderDocument.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digits.count == 11 {
            // CPF: 000.000.000-00
            return String(format: "%@.%@.%@-%@",
                         String(digits.prefix(3)),
                         String(digits.dropFirst(3).prefix(3)),
                         String(digits.dropFirst(6).prefix(3)),
                         String(digits.suffix(2)))
        } else if digits.count == 14 {
            // CNPJ: 00.000.000/0000-00
            return String(format: "%@.%@.%@/%@-%@",
                         String(digits.prefix(2)),
                         String(digits.dropFirst(2).prefix(3)),
                         String(digits.dropFirst(5).prefix(3)),
                         String(digits.dropFirst(8).prefix(4)),
                         String(digits.suffix(2)))
        }
        
        return accountHolderDocument
    }
}

enum AccountType: String, CaseIterable, Codable {
    case checking = "checking"
    case savings = "savings"
    
    var displayName: String {
        switch self {
        case .checking:
            return "Conta Corrente"
        case .savings:
            return "Conta Poupança"
        }
    }
    
    var shortName: String {
        switch self {
        case .checking:
            return "CC"
        case .savings:
            return "CP"
        }
    }
}

// MARK: - Payment Analytics
struct PaymentAnalytics: Codable {
    let totalRevenue: Decimal
    let monthlyRevenue: Decimal
    let averagePaymentValue: Decimal
    let paymentSuccessRate: Double
    let totalTransactions: Int
    let activeSubscriptions: Int
    let churnRate: Double
    let period: AnalyticsPeriod
    let lastUpdated: Date
    
    var formattedTotalRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: totalRevenue as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedMonthlyRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: monthlyRevenue as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", paymentSuccessRate * 100)
    }
    
    var formattedChurnRate: String {
        return String(format: "%.1f%%", churnRate * 100)
    }
}

enum AnalyticsPeriod: String, CaseIterable, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week:
            return "Última Semana"
        case .month:
            return "Último Mês"
        case .quarter:
            return "Último Trimestre"
        case .year:
            return "Último Ano"
        }
    }
}

// MARK: - Mock Data Extensions
extension PatientPayment {
    static let mockPending = PatientPayment(
        patientId: UUID(),
        psychologistId: UUID(),
        amount: 180.00,
        status: .pending,
        paymentMethod: .mockCard,
        billingPeriod: BillingPeriod(
            startDate: Calendar.current.startOfMonth(for: Date()) ?? Date(),
            endDate: Calendar.current.endOfMonth(for: Date()) ?? Date()
        ),
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    )
    
    static let mockOverdue = PatientPayment(
        patientId: UUID(),
        psychologistId: UUID(),
        amount: 180.00,
        status: .pending,
        paymentMethod: .mockCard,
        billingPeriod: BillingPeriod(
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            endDate: Calendar.current.startOfMonth(for: Date()) ?? Date()
        ),
        dueDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )
    
    static let mockPaid = PatientPayment(
        patientId: UUID(),
        psychologistId: UUID(),
        amount: 180.00,
        status: .succeeded,
        paymentMethod: .mockCard,
        billingPeriod: BillingPeriod(
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            endDate: Calendar.current.startOfMonth(for: Date()) ?? Date()
        ),
        dueDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        paidDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
        stripePaymentIntentId: "pi_1234567890",
        stripeChargeId: "ch_1234567890"
    )
}

extension PsychologistEarnings {
    static let mock = PsychologistEarnings(
        psychologistId: UUID(),
        totalEarnings: 15000.00,
        availableForWithdrawal: 2500.00,
        pendingEarnings: 800.00,
        totalWithdrawn: 12000.00,
        platformFee: 1500.00,
        netEarnings: 13500.00
    )
}

extension BankAccount {
    static let mock = BankAccount(
        psychologistId: UUID(),
        bankCode: "001",
        bankName: "Banco do Brasil",
        accountType: .checking,
        accountNumber: "123456789",
        routingNumber: "1234",
        accountHolderName: "Ana Silva",
        accountHolderDocument: "12345678901",
        isDefault: true,
        isVerified: true
    )
}

// MARK: - Calendar Extensions
extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
    
    func endOfMonth(for date: Date) -> Date? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return self.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
    }
}
