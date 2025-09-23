//
//  StripeConnectModels.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Transaction Models

struct ConnectTransaction: Identifiable, Codable {
    let id: String
    let amount: Int
    let currency: String
    let applicationFeeAmount: Int
    let netAmount: Int
    let status: TransactionStatus
    let createdAt: Date
    let description: String?
    let psychologistId: String
    let patientId: String
    let sessionId: String?
    let paymentIntentId: String
    let transferId: String?
    
    var formattedAmount: String {
        let value = Double(amount) / 100.0
        return String(format: "R$ %.2f", value)
    }
    
    var formattedFee: String {
        let value = Double(applicationFeeAmount) / 100.0
        return String(format: "R$ %.2f", value)
    }
    
    var formattedNetAmount: String {
        let value = Double(netAmount) / 100.0
        return String(format: "R$ %.2f", value)
    }
}

enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case succeeded = "succeeded"
    case failed = "failed"
    case canceled = "canceled"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .succeeded:
            return "Concluído"
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
        case .succeeded:
            return .green
        case .failed, .canceled:
            return .red
        case .refunded:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .succeeded:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        case .canceled:
            return "minus.circle"
        case .refunded:
            return "arrow.counterclockwise.circle"
        }
    }
}

// MARK: - Payout Models

struct ConnectPayout: Identifiable, Codable {
    let id: String
    let amount: Int
    let currency: String
    let status: PayoutStatus
    let arrivalDate: Date
    let createdAt: Date
    let description: String?
    let accountId: String
    let bankAccount: BankAccountInfo?
    
    var formattedAmount: String {
        let value = Double(amount) / 100.0
        return String(format: "R$ %.2f", value)
    }
}

enum PayoutStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inTransit = "in_transit"
    case paid = "paid"
    case failed = "failed"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .inTransit:
            return "Em Trânsito"
        case .paid:
            return "Pago"
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
        case .inTransit:
            return .blue
        case .paid:
            return .green
        case .failed, .canceled:
            return .red
        }
    }
}

struct BankAccountInfo: Codable {
    let bankName: String
    let last4: String
    let accountType: String
}

// MARK: - Fee Configuration

struct FeeConfiguration: Codable {
    let platformFeePercentage: Double
    let minimumFeeAmount: Int
    let maximumFeeAmount: Int?
    let fixedFeeAmount: Int?
    
    static let `default` = FeeConfiguration(
        platformFeePercentage: 0.10, // 10%
        minimumFeeAmount: 500, // R$ 5,00
        maximumFeeAmount: nil,
        fixedFeeAmount: nil
    )
    
    func calculateFee(for amount: Int) -> Int {
        let percentageFee = Int(Double(amount) * platformFeePercentage)
        var totalFee = percentageFee
        
        if let fixedFee = fixedFeeAmount {
            totalFee += fixedFee
        }
        
        totalFee = max(totalFee, minimumFeeAmount)
        
        if let maxFee = maximumFeeAmount {
            totalFee = min(totalFee, maxFee)
        }
        
        return totalFee
    }
}

// MARK: - Session Payment Models

struct SessionPayment: Identifiable, Codable {
    let id: String
    let sessionId: String
    let psychologistId: String
    let patientId: String
    let amount: Int
    let currency: String
    let status: SessionPaymentStatus
    let scheduledDate: Date
    let completedDate: Date?
    let paymentMethod: PaymentMethodType
    let description: String
    
    var formattedAmount: String {
        let value = Double(amount) / 100.0
        return String(format: "R$ %.2f", value)
    }
}

enum SessionPaymentStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    
    var displayName: String {
        switch self {
        case .scheduled:
            return "Agendado"
        case .processing:
            return "Processando"
        case .completed:
            return "Concluído"
        case .failed:
            return "Falhou"
        case .refunded:
            return "Reembolsado"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled:
            return .blue
        case .processing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .refunded:
            return .purple
        }
    }
}

enum PaymentMethodType: String, Codable, CaseIterable {
    case card = "card"
    case pix = "pix"
    case bankTransfer = "bank_transfer"
    case boleto = "boleto"
    
    var displayName: String {
        switch self {
        case .card:
            return "Cartão"
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
        case .card:
            return "creditcard"
        case .pix:
            return "qrcode"
        case .bankTransfer:
            return "building.columns"
        case .boleto:
            return "doc.text"
        }
    }
}

// MARK: - Analytics Models

struct ConnectAnalytics: Codable {
    let totalRevenue: Int
    let totalFees: Int
    let totalPayouts: Int
    let transactionCount: Int
    let averageTransactionAmount: Int
    let period: AnalyticsPeriod
    let lastUpdated: Date
    
    var formattedTotalRevenue: String {
        let value = Double(totalRevenue) / 100.0
        return String(format: "R$ %.2f", value)
    }
    
    var formattedTotalFees: String {
        let value = Double(totalFees) / 100.0
        return String(format: "R$ %.2f", value)
    }
    
    var formattedTotalPayouts: String {
        let value = Double(totalPayouts) / 100.0
        return String(format: "R$ %.2f", value)
    }
    
    var formattedAverageTransaction: String {
        let value = Double(averageTransactionAmount) / 100.0
        return String(format: "R$ %.2f", value)
    }
}

enum AnalyticsPeriod: String, Codable, CaseIterable {
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

// MARK: - Dispute Models

struct ConnectDispute: Identifiable, Codable {
    let id: String
    let amount: Int
    let currency: String
    let reason: DisputeReason
    let status: DisputeStatus
    let createdAt: Date
    let evidenceDueBy: Date?
    let chargeId: String
    let description: String?
    
    var formattedAmount: String {
        let value = Double(amount) / 100.0
        return String(format: "R$ %.2f", value)
    }
}

enum DisputeReason: String, Codable, CaseIterable {
    case fraudulent = "fraudulent"
    case subscriptionCanceled = "subscription_canceled"
    case productUnacceptable = "product_unacceptable"
    case productNotReceived = "product_not_received"
    case unrecognized = "unrecognized"
    case duplicate = "duplicate"
    case creditNotProcessed = "credit_not_processed"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .fraudulent:
            return "Fraudulento"
        case .subscriptionCanceled:
            return "Assinatura Cancelada"
        case .productUnacceptable:
            return "Serviço Inaceitável"
        case .productNotReceived:
            return "Serviço Não Recebido"
        case .unrecognized:
            return "Não Reconhecido"
        case .duplicate:
            return "Duplicado"
        case .creditNotProcessed:
            return "Crédito Não Processado"
        case .general:
            return "Geral"
        }
    }
}

enum DisputeStatus: String, Codable, CaseIterable {
    case warningNeedsResponse = "warning_needs_response"
    case warningUnderReview = "warning_under_review"
    case warningClosed = "warning_closed"
    case needsResponse = "needs_response"
    case underReview = "under_review"
    case chargeRefunded = "charge_refunded"
    case won = "won"
    case lost = "lost"
    
    var displayName: String {
        switch self {
        case .warningNeedsResponse:
            return "Aviso - Resposta Necessária"
        case .warningUnderReview:
            return "Aviso - Em Análise"
        case .warningClosed:
            return "Aviso - Fechado"
        case .needsResponse:
            return "Resposta Necessária"
        case .underReview:
            return "Em Análise"
        case .chargeRefunded:
            return "Reembolsado"
        case .won:
            return "Ganho"
        case .lost:
            return "Perdido"
        }
    }
    
    var color: Color {
        switch self {
        case .warningNeedsResponse, .needsResponse:
            return .orange
        case .warningUnderReview, .underReview:
            return .blue
        case .warningClosed, .won:
            return .green
        case .chargeRefunded, .lost:
            return .red
        }
    }
}
