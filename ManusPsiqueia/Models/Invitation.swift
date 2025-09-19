//
//  Invitation.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Invitation Model
struct Invitation: Identifiable, Codable, Hashable {
    let id: UUID
    let fromPatientId: UUID
    let toPsychologistEmail: String
    let toPsychologistName: String?
    let patientName: String
    let patientEmail: String
    let message: String?
    let status: InvitationStatus
    let invitationCode: String
    let expiresAt: Date
    let sentAt: Date
    let respondedAt: Date?
    let acceptedAt: Date?
    let rejectedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        fromPatientId: UUID,
        toPsychologistEmail: String,
        toPsychologistName: String? = nil,
        patientName: String,
        patientEmail: String,
        message: String? = nil,
        status: InvitationStatus = .pending,
        invitationCode: String = generateInvitationCode(),
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        sentAt: Date = Date(),
        respondedAt: Date? = nil,
        acceptedAt: Date? = nil,
        rejectedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fromPatientId = fromPatientId
        self.toPsychologistEmail = toPsychologistEmail
        self.toPsychologistName = toPsychologistName
        self.patientName = patientName
        self.patientEmail = patientEmail
        self.message = message
        self.status = status
        self.invitationCode = invitationCode
        self.expiresAt = expiresAt
        self.sentAt = sentAt
        self.respondedAt = respondedAt
        self.acceptedAt = acceptedAt
        self.rejectedAt = rejectedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var canBeAccepted: Bool {
        return status == .pending && !isExpired
    }
    
    var daysUntilExpiration: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, days)
    }
    
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: expiresAt)
    }
    
    var formattedSentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: sentAt)
    }
    
    var statusMessage: String {
        switch status {
        case .pending:
            if isExpired {
                return "Convite expirado"
            } else if daysUntilExpiration <= 1 {
                return "Expira hoje"
            } else {
                return "Aguardando resposta"
            }
        case .accepted:
            return "Convite aceito"
        case .rejected:
            return "Convite recusado"
        case .expired:
            return "Convite expirado"
        case .canceled:
            return "Convite cancelado"
        }
    }
    
    static func generateInvitationCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Invitation Status
enum InvitationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendente"
        case .accepted:
            return "Aceito"
        case .rejected:
            return "Recusado"
        case .expired:
            return "Expirado"
        case .canceled:
            return "Cancelado"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .gray
        case .canceled:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .accepted:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .canceled:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Patient-Psychologist Link
struct PatientPsychologistLink: Identifiable, Codable, Hashable {
    let id: UUID
    let patientId: UUID
    let psychologistId: UUID
    let linkedAt: Date
    let isActive: Bool
    let monthlyFee: Decimal
    let paymentDueDate: Date?
    let lastPaymentDate: Date?
    let totalPaid: Decimal
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        patientId: UUID,
        psychologistId: UUID,
        linkedAt: Date = Date(),
        isActive: Bool = true,
        monthlyFee: Decimal,
        paymentDueDate: Date? = nil,
        lastPaymentDate: Date? = nil,
        totalPaid: Decimal = 0,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.patientId = patientId
        self.psychologistId = psychologistId
        self.linkedAt = linkedAt
        self.isActive = isActive
        self.monthlyFee = monthlyFee
        self.paymentDueDate = paymentDueDate
        self.lastPaymentDate = lastPaymentDate
        self.totalPaid = totalPaid
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var formattedMonthlyFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: monthlyFee as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedTotalPaid: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: totalPaid as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedLinkedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: linkedAt)
    }
    
    var linkDuration: String {
        let components = Calendar.current.dateComponents([.month, .day], from: linkedAt, to: Date())
        let months = components.month ?? 0
        let days = components.day ?? 0
        
        if months > 0 {
            return "\(months) mês\(months == 1 ? "" : "es")"
        } else {
            return "\(days) dia\(days == 1 ? "" : "s")"
        }
    }
    
    var paymentStatus: PaymentStatus {
        guard let dueDate = paymentDueDate else { return .inactive }
        
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        
        if daysUntilDue < 0 {
            return .expired
        } else if daysUntilDue <= 3 {
            return .expiringSoon
        } else {
            return .active
        }
    }
}

// MARK: - Invitation Template
struct InvitationTemplate {
    static func generateEmailSubject(patientName: String) -> String {
        return "Convite para se juntar ao Manus Psiqueia - \(patientName)"
    }
    
    static func generateEmailBody(
        patientName: String,
        patientEmail: String,
        message: String?,
        invitationCode: String
    ) -> String {
        let customMessage = message.map { "\n\nMensagem pessoal:\n\"\($0)\"\n" } ?? ""
        
        return """
        Olá!
        
        Você recebeu um convite para se juntar ao Manus Psiqueia como psicólogo(a).
        
        **Detalhes do convite:**
        • Paciente: \(patientName)
        • Email: \(patientEmail)
        • Código do convite: \(invitationCode)\(customMessage)
        
        **Sobre o Manus Psiqueia:**
        O Manus Psiqueia é uma plataforma premium de psicologia digital que oferece:
        
        ✅ Gestão completa de pacientes
        ✅ Sistema de pagamentos automatizado
        ✅ Dashboard financeiro avançado
        ✅ Ferramentas de IA para análise
        ✅ Chat seguro e privado
        ✅ Relatórios detalhados
        
        **Como funciona:**
        1. Faça sua assinatura por apenas R$ 89,90/mês
        2. Configure seu perfil profissional
        3. Defina seus honorários e disponibilidade
        4. Comece a atender seus pacientes
        5. Receba pagamentos automaticamente
        
        **Aceitar convite:**
        Para aceitar este convite e começar a usar a plataforma:
        
        1. Baixe o app Manus Psiqueia na App Store
        2. Crie sua conta como psicólogo(a)
        3. Use o código: \(invitationCode)
        4. Complete seu perfil profissional
        5. Assine o plano mensal
        
        Este convite expira em 7 dias.
        
        ---
        
        **Manus Psiqueia**
        Inteligência Artificial em Saúde Mental
        
        AiLun Tecnologia
        CNPJ: 60.740.536/0001-75
        contato@ailun.com.br
        
        Se você não deseja receber esses emails, pode ignorar esta mensagem.
        """
    }
    
    static func generateSMSBody(
        patientName: String,
        invitationCode: String
    ) -> String {
        return """
        🧠 Manus Psiqueia
        
        Olá! \(patientName) te convidou para ser psicólogo(a) na nossa plataforma.
        
        Código: \(invitationCode)
        
        Baixe o app e use este código para aceitar o convite.
        
        Plataforma premium com IA, gestão de pacientes e pagamentos automáticos.
        
        Expira em 7 dias.
        """
    }
}

// MARK: - Invitation Analytics
struct InvitationAnalytics: Codable {
    let totalInvitationsSent: Int
    let totalInvitationsAccepted: Int
    let totalInvitationsRejected: Int
    let totalInvitationsExpired: Int
    let acceptanceRate: Double
    let averageResponseTime: TimeInterval // em segundos
    let topInvitingPatients: [PatientInvitationStats]
    let recentInvitations: [Invitation]
    let period: AnalyticsPeriod
    let lastUpdated: Date
    
    var formattedAcceptanceRate: String {
        return String(format: "%.1f%%", acceptanceRate * 100)
    }
    
    var formattedAverageResponseTime: String {
        let hours = Int(averageResponseTime / 3600)
        if hours > 24 {
            let days = hours / 24
            return "\(days) dia\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hora\(hours == 1 ? "" : "s")"
        } else {
            let minutes = Int(averageResponseTime / 60)
            return "\(minutes) minuto\(minutes == 1 ? "" : "s")"
        }
    }
}

struct PatientInvitationStats: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let patientName: String
    let totalInvitationsSent: Int
    let totalInvitationsAccepted: Int
    let successRate: Double
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
}

// MARK: - Notification Models
struct InvitationNotification: Identifiable, Codable {
    let id: UUID
    let invitationId: UUID
    let recipientEmail: String
    let type: NotificationType
    let status: NotificationStatus
    let sentAt: Date?
    let deliveredAt: Date?
    let openedAt: Date?
    let clickedAt: Date?
    let errorMessage: String?
    let createdAt: Date
    
    enum NotificationType: String, CaseIterable, Codable {
        case email = "email"
        case sms = "sms"
        case push = "push"
        case inApp = "in_app"
        
        var displayName: String {
            switch self {
            case .email:
                return "Email"
            case .sms:
                return "SMS"
            case .push:
                return "Push"
            case .inApp:
                return "In-App"
            }
        }
    }
    
    enum NotificationStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case sent = "sent"
        case delivered = "delivered"
        case opened = "opened"
        case clicked = "clicked"
        case failed = "failed"
        
        var displayName: String {
            switch self {
            case .pending:
                return "Pendente"
            case .sent:
                return "Enviado"
            case .delivered:
                return "Entregue"
            case .opened:
                return "Aberto"
            case .clicked:
                return "Clicado"
            case .failed:
                return "Falhou"
            }
        }
        
        var color: Color {
            switch self {
            case .pending:
                return .orange
            case .sent:
                return .blue
            case .delivered:
                return .green
            case .opened:
                return .purple
            case .clicked:
                return .pink
            case .failed:
                return .red
            }
        }
    }
}

// MARK: - Mock Data Extensions
extension Invitation {
    static let mockPending = Invitation(
        fromPatientId: UUID(),
        toPsychologistEmail: "dr.silva@email.com",
        toPsychologistName: "Dr. Ana Silva",
        patientName: "João Santos",
        patientEmail: "joao@email.com",
        message: "Gostaria muito de ter você como minha psicóloga. Tenho acompanhado seu trabalho e acredito que seria uma ótima parceria.",
        status: .pending,
        expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    )
    
    static let mockAccepted = Invitation(
        fromPatientId: UUID(),
        toPsychologistEmail: "dr.costa@email.com",
        toPsychologistName: "Dr. Carlos Costa",
        patientName: "Maria Oliveira",
        patientEmail: "maria@email.com",
        status: .accepted,
        acceptedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())
    )
    
    static let mockExpired = Invitation(
        fromPatientId: UUID(),
        toPsychologistEmail: "dr.santos@email.com",
        patientName: "Pedro Lima",
        patientEmail: "pedro@email.com",
        status: .expired,
        expiresAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )
}

extension PatientPsychologistLink {
    static let mockActive = PatientPsychologistLink(
        patientId: UUID(),
        psychologistId: UUID(),
        linkedAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        isActive: true,
        monthlyFee: 180.00,
        paymentDueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
        lastPaymentDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
        totalPaid: 540.00
    )
    
    static let mockInactive = PatientPsychologistLink(
        patientId: UUID(),
        psychologistId: UUID(),
        linkedAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
        isActive: false,
        monthlyFee: 150.00,
        lastPaymentDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
        totalPaid: 600.00,
        notes: "Psicólogo cancelou assinatura"
    )
}

extension InvitationAnalytics {
    static let mock = InvitationAnalytics(
        totalInvitationsSent: 150,
        totalInvitationsAccepted: 89,
        totalInvitationsRejected: 23,
        totalInvitationsExpired: 38,
        acceptanceRate: 0.593,
        averageResponseTime: 172800, // 2 dias
        topInvitingPatients: [
            PatientInvitationStats(
                id: UUID(),
                patientId: UUID(),
                patientName: "João Santos",
                totalInvitationsSent: 5,
                totalInvitationsAccepted: 4,
                successRate: 0.8
            ),
            PatientInvitationStats(
                id: UUID(),
                patientId: UUID(),
                patientName: "Maria Oliveira",
                totalInvitationsSent: 3,
                totalInvitationsAccepted: 3,
                successRate: 1.0
            )
        ],
        recentInvitations: [.mockPending, .mockAccepted],
        period: .month,
        lastUpdated: Date()
    )
}
