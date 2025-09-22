//
//  Financial.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Financial Data
struct FinancialData: Codable {
    let availableBalance: Decimal
    let totalRevenue: Decimal
    let monthlyRevenue: Decimal
    let activePatients: Int
    let conversionRate: Double
    let platformFeePercentage: Double
    let nextPayoutDate: String
    let revenueChartData: [RevenueChartPoint]
    let recentPayments: [PatientPayment]
    let recentWithdrawals: [Withdrawal]
    let recentTransactions: [Transaction]
    let revenueTrend: TrendData?
    let patientsTrend: TrendData?
    let monthlyTrend: TrendData?
    let conversionTrend: TrendData?
    let period: FinancialPeriod
    let lastUpdated: Date
    
    var formattedAvailableBalance: String {
        return formatCurrency(availableBalance)
    }
    
    var formattedTotalRevenue: String {
        return formatCurrency(totalRevenue)
    }
    
    var formattedMonthlyRevenue: String {
        return formatCurrency(monthlyRevenue)
    }
    
    var formattedConversionRate: String {
        return String(format: "%.1f%%", conversionRate * 100)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
}

// MARK: - Financial Period
enum FinancialPeriod: String, CaseIterable, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week:
            return "Semana"
        case .month:
            return "Mês"
        case .quarter:
            return "Trimestre"
        case .year:
            return "Ano"
        }
    }
    
    var days: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .quarter:
            return 90
        case .year:
            return 365
        }
    }
}

// MARK: - Revenue Chart Data
struct RevenueChartPoint: Identifiable, Codable {
    let id = UUID()
    let month: String
    let revenue: Double
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case month, revenue, date
    }
}

// MARK: - Trend Data
struct TrendData: Codable {
    let percentage: Double
    let isPositive: Bool
    let period: String
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", abs(percentage))
    }
    
    var description: String {
        let direction = isPositive ? "aumento" : "diminuição"
        return "\(formattedPercentage) de \(direction) em relação ao \(period)"
    }
}

// MARK: - Patient Payment
struct PatientPayment: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let patientName: String
    let amount: Decimal
    let status: PaymentStatus
    let dueDate: Date
    let paidDate: Date?
    let method: PaymentMethod
    let description: String
    let createdAt: Date
    
    var patientInitials: String {
        let components = patientName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: paidDate ?? dueDate)
    }
    
    var isOverdue: Bool {
        guard status != .paid else { return false }
        return Date() > dueDate
    }
    
    var daysSinceOverdue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
}

// MARK: - Payment Status
enum PaymentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case paid = "paid"
    case overdue = "overdue"
    case failed = "failed"
    case refunded = "refunded"
    case canceled = "canceled"
    case active = "active"
    case expiringSoon = "expiring_soon"
    case expired = "expired"
    case inactive = "inactive"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .paid:
            return "Pago"
        case .overdue:
            return "Atrasado"
        case .failed:
            return "Falhou"
        case .refunded:
            return "Reembolsado"
        case .canceled:
            return "Cancelado"
        case .active:
            return "Ativo"
        case .expiringSoon:
            return "Vence em breve"
        case .expired:
            return "Vencido"
        case .inactive:
            return "Inativo"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .paid:
            return .green
        case .overdue:
            return .red
        case .failed:
            return .red
        case .refunded:
            return .blue
        case .canceled:
            return .gray
        case .active:
            return .green
        case .expiringSoon:
            return .orange
        case .expired:
            return .red
        case .inactive:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .paid:
            return "checkmark.circle.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .refunded:
            return "arrow.counterclockwise.circle.fill"
        case .canceled:
            return "minus.circle.fill"
        case .active:
            return "checkmark.circle.fill"
        case .expiringSoon:
            return "clock.badge.exclamationmark.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .inactive:
            return "pause.circle.fill"
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, CaseIterable, Codable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case pix = "pix"
    case bankTransfer = "bank_transfer"
    case boleto = "boleto"
    
    var displayName: String {
        switch self {
        case .creditCard:
            return "Cartão de Crédito"
        case .debitCard:
            return "Cartão de Débito"
        case .pix:
            return "PIX"
        case .bankTransfer:
            return "Transferência Bancária"
        case .boleto:
            return "Boleto"
        }
    }
    
    var icon: String {
        switch self {
        case .creditCard:
            return "creditcard.fill"
        case .debitCard:
            return "creditcard"
        case .pix:
            return "qrcode"
        case .bankTransfer:
            return "building.columns.fill"
        case .boleto:
            return "doc.text.fill"
        }
    }
}

// MARK: - Withdrawal
struct Withdrawal: Identifiable, Codable {
    let id: UUID
    let amount: Decimal
    let status: WithdrawalStatus
    let requestedAt: Date
    let processedAt: Date?
    let completedAt: Date?
    let bankAccount: BankAccount?
    let fee: Decimal
    let netAmount: Decimal
    let description: String?
    let stripeTransferId: String?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedNetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: netAmount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: fee as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: completedAt ?? processedAt ?? requestedAt)
    }
    
    var estimatedArrival: String {
        guard status == .processing else { return "N/A" }
        
        let calendar = Calendar.current
        let arrivalDate = calendar.date(byAdding: .day, value: 2, to: requestedAt) ?? requestedAt
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: arrivalDate)
    }
}

// MARK: - Withdrawal Status
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
struct BankAccount: Codable {
    let id: UUID
    let bankName: String
    let bankCode: String
    let accountType: AccountType
    let accountNumber: String
    let agency: String
    let holderName: String
    let holderDocument: String
    let isDefault: Bool
    let isVerified: Bool
    let createdAt: Date
    
    enum AccountType: String, CaseIterable, Codable {
        case checking = "checking"
        case savings = "savings"
        
        var displayName: String {
            switch self {
            case .checking:
                return "Conta Corrente"
            case .savings:
                return "Poupança"
            }
        }
    }
    
    var maskedAccountNumber: String {
        let suffix = String(accountNumber.suffix(4))
        return "****-\(suffix)"
    }
    
    var formattedAccount: String {
        return "\(bankName) - \(accountType.displayName) \(maskedAccountNumber)"
    }
}

// MARK: - Transaction
struct Transaction: Identifiable, Codable {
    let id: UUID
    let type: TransactionType
    let amount: Decimal
    let description: String
    let status: TransactionStatus
    let createdAt: Date
    let relatedEntityId: UUID?
    let relatedEntityType: String?
    let metadata: [String: String]?
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        let sign = isPositive ? "+" : "-"
        let value = formatter.string(from: abs(amount) as NSDecimalNumber) ?? "R$ 0,00"
        return "\(sign)\(value)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: createdAt)
    }
    
    var isPositive: Bool {
        return type.isPositive
    }
    
    var icon: String {
        return type.icon
    }
    
    var color: Color {
        return type.color
    }
}

// MARK: - Transaction Type
enum TransactionType: String, CaseIterable, Codable {
    case patientPayment = "patient_payment"
    case subscriptionFee = "subscription_fee"
    case platformFee = "platform_fee"
    case withdrawal = "withdrawal"
    case refund = "refund"
    case chargeback = "chargeback"
    case bonus = "bonus"
    case adjustment = "adjustment"
    
    var displayName: String {
        switch self {
        case .patientPayment:
            return "Pagamento de Paciente"
        case .subscriptionFee:
            return "Taxa de Assinatura"
        case .platformFee:
            return "Taxa da Plataforma"
        case .withdrawal:
            return "Saque"
        case .refund:
            return "Reembolso"
        case .chargeback:
            return "Chargeback"
        case .bonus:
            return "Bônus"
        case .adjustment:
            return "Ajuste"
        }
    }
    
    var isPositive: Bool {
        switch self {
        case .patientPayment, .bonus, .adjustment:
            return true
        case .subscriptionFee, .platformFee, .withdrawal, .refund, .chargeback:
            return false
        }
    }
    
    var icon: String {
        switch self {
        case .patientPayment:
            return "person.crop.circle.badge.plus"
        case .subscriptionFee:
            return "crown.fill"
        case .platformFee:
            return "percent"
        case .withdrawal:
            return "arrow.down.circle.fill"
        case .refund:
            return "arrow.counterclockwise.circle.fill"
        case .chargeback:
            return "exclamationmark.triangle.fill"
        case .bonus:
            return "gift.fill"
        case .adjustment:
            return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .patientPayment, .bonus:
            return .green
        case .subscriptionFee:
            return .purple
        case .platformFee:
            return .orange
        case .withdrawal:
            return .blue
        case .refund:
            return .yellow
        case .chargeback:
            return .red
        case .adjustment:
            return .gray
        }
    }
}

// MARK: - Transaction Status
enum TransactionStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
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
        case .completed:
            return .green
        case .failed:
            return .red
        case .canceled:
            return .gray
        }
    }
}

// MARK: - Financial Summary
struct FinancialSummary: Codable {
    let totalEarnings: Decimal
    let totalWithdrawals: Decimal
    let pendingBalance: Decimal
    let availableBalance: Decimal
    let totalPatients: Int
    let activePatients: Int
    let monthlyRecurringRevenue: Decimal
    let averageSessionValue: Decimal
    let conversionRate: Double
    let churnRate: Double
    let lifetimeValue: Decimal
    let period: FinancialPeriod
    let lastUpdated: Date
    
    var formattedTotalEarnings: String {
        return formatCurrency(totalEarnings)
    }
    
    var formattedTotalWithdrawals: String {
        return formatCurrency(totalWithdrawals)
    }
    
    var formattedPendingBalance: String {
        return formatCurrency(pendingBalance)
    }
    
    var formattedAvailableBalance: String {
        return formatCurrency(availableBalance)
    }
    
    var formattedMonthlyRecurringRevenue: String {
        return formatCurrency(monthlyRecurringRevenue)
    }
    
    var formattedAverageSessionValue: String {
        return formatCurrency(averageSessionValue)
    }
    
    var formattedLifetimeValue: String {
        return formatCurrency(lifetimeValue)
    }
    
    var formattedConversionRate: String {
        return String(format: "%.1f%%", conversionRate * 100)
    }
    
    var formattedChurnRate: String {
        return String(format: "%.1f%%", churnRate * 100)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
}

// MARK: - Analytics Period
enum AnalyticsPeriod: String, CaseIterable, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day:
            return "Hoje"
        case .week:
            return "Esta Semana"
        case .month:
            return "Este Mês"
        case .quarter:
            return "Este Trimestre"
        case .year:
            return "Este Ano"
        }
    }
}

// MARK: - Mock Data Extensions
extension FinancialData {
    static let mock = FinancialData(
        availableBalance: 2450.80,
        totalRevenue: 15680.00,
        monthlyRevenue: 3200.00,
        activePatients: 18,
        conversionRate: 0.75,
        platformFeePercentage: 8.5,
        nextPayoutDate: "15 de Janeiro",
        revenueChartData: [
            RevenueChartPoint(month: "Set", revenue: 2800, date: Date()),
            RevenueChartPoint(month: "Out", revenue: 3200, date: Date()),
            RevenueChartPoint(month: "Nov", revenue: 2950, date: Date()),
            RevenueChartPoint(month: "Dez", revenue: 3400, date: Date()),
            RevenueChartPoint(month: "Jan", revenue: 3200, date: Date())
        ],
        recentPayments: [
            PatientPayment.mockPaid,
            PatientPayment.mockPending,
            PatientPayment.mockOverdue
        ],
        recentWithdrawals: [
            Withdrawal.mockCompleted,
            Withdrawal.mockProcessing
        ],
        recentTransactions: [
            Transaction.mockPatientPayment,
            Transaction.mockSubscriptionFee,
            Transaction.mockWithdrawal
        ],
        revenueTrend: TrendData(percentage: 12.5, isPositive: true, period: "mês anterior"),
        patientsTrend: TrendData(percentage: 8.3, isPositive: true, period: "mês anterior"),
        monthlyTrend: TrendData(percentage: 15.2, isPositive: true, period: "mês anterior"),
        conversionTrend: TrendData(percentage: 5.1, isPositive: false, period: "mês anterior"),
        period: .month,
        lastUpdated: Date()
    )
}

extension PatientPayment {
    static let mockPaid = PatientPayment(
        id: UUID(),
        patientId: UUID(),
        patientName: "Maria Silva",
        amount: 180.00,
        status: .paid,
        dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        paidDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        method: .pix,
        description: "Sessão de terapia - Janeiro 2024",
        createdAt: Date()
    )
    
    static let mockPending = PatientPayment(
        id: UUID(),
        patientId: UUID(),
        patientName: "João Santos",
        amount: 200.00,
        status: .pending,
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        paidDate: nil,
        method: .creditCard,
        description: "Sessão de terapia - Janeiro 2024",
        createdAt: Date()
    )
    
    static let mockOverdue = PatientPayment(
        id: UUID(),
        patientId: UUID(),
        patientName: "Ana Costa",
        amount: 150.00,
        status: .overdue,
        dueDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
        paidDate: nil,
        method: .boleto,
        description: "Sessão de terapia - Dezembro 2023",
        createdAt: Date()
    )
}

extension Withdrawal {
    static let mockCompleted = Withdrawal(
        id: UUID(),
        amount: 1500.00,
        status: .completed,
        requestedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        processedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
        completedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        bankAccount: BankAccount.mock,
        fee: 15.00,
        netAmount: 1485.00,
        description: "Saque mensal",
        stripeTransferId: "tr_1234567890"
    )
    
    static let mockProcessing = Withdrawal(
        id: UUID(),
        amount: 800.00,
        status: .processing,
        requestedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        processedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        completedAt: nil,
        bankAccount: BankAccount.mock,
        fee: 8.00,
        netAmount: 792.00,
        description: "Saque parcial",
        stripeTransferId: "tr_0987654321"
    )
}

extension BankAccount {
    static let mock = BankAccount(
        id: UUID(),
        bankName: "Banco do Brasil",
        bankCode: "001",
        accountType: .checking,
        accountNumber: "123456789",
        agency: "1234",
        holderName: "Dr. João Silva",
        holderDocument: "123.456.789-00",
        isDefault: true,
        isVerified: true,
        createdAt: Date()
    )
}

extension Transaction {
    static let mockPatientPayment = Transaction(
        id: UUID(),
        type: .patientPayment,
        amount: 180.00,
        description: "Pagamento de Maria Silva",
        status: .completed,
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        relatedEntityId: UUID(),
        relatedEntityType: "patient_payment",
        metadata: ["patient_name": "Maria Silva"]
    )
    
    static let mockSubscriptionFee = Transaction(
        id: UUID(),
        type: .subscriptionFee,
        amount: 89.90,
        description: "Taxa de assinatura mensal",
        status: .completed,
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        relatedEntityId: nil,
        relatedEntityType: "subscription",
        metadata: nil
    )
    
    static let mockWithdrawal = Transaction(
        id: UUID(),
        type: .withdrawal,
        amount: 1500.00,
        description: "Saque para conta bancária",
        status: .completed,
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
        relatedEntityId: UUID(),
        relatedEntityType: "withdrawal",
        metadata: ["bank_account": "Banco do Brasil ****-6789"]
    )
}
