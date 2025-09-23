import ManusPsiqueiaServices
//
//  InvitationManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Invitation Manager
@MainActor
class InvitationManager: ObservableObject {
    @Published var sentInvitations: [Invitation] = []
    @Published var receivedInvitations: [Invitation] = []
    @Published var patientLinks: [PatientPsychologistLink] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let networkManager = NetworkManager.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationObservers()
    }
    
    // MARK: - Setup
    private func setupNotificationObservers() {
        // Observar mudanças de autenticação
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] _ in
                Task {
                    await self?.loadUserInvitations()
                    await self?.loadPatientLinks()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogout)
            .sink { [weak self] _ in
                self?.clearData()
            }
            .store(in: &cancellables)
    }
    
    private func clearData() {
        sentInvitations.removeAll()
        receivedInvitations.removeAll()
        patientLinks.removeAll()
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Load Data
    func loadUserInvitations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Carregar convites enviados (para pacientes)
            let sentResponse: InvitationListResponse = try await networkManager.get(
                endpoint: "/invitations/sent"
            )
            
            // Carregar convites recebidos (para psicólogos)
            let receivedResponse: InvitationListResponse = try await networkManager.get(
                endpoint: "/invitations/received"
            )
            
            DispatchQueue.main.async {
                self.sentInvitations = sentResponse.invitations
                self.receivedInvitations = receivedResponse.invitations
            }
        } catch {
            errorMessage = "Erro ao carregar convites: \(error.localizedDescription)"
        }
    }
    
    func loadPatientLinks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: PatientLinksResponse = try await networkManager.get(
                endpoint: "/patient-links"
            )
            
            DispatchQueue.main.async {
                self.patientLinks = response.links
            }
        } catch {
            errorMessage = "Erro ao carregar vinculações: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Send Invitation
    func sendInvitation(
        toPsychologistEmail: String,
        toPsychologistName: String? = nil,
        message: String? = nil,
        fromPatient: User
    ) async throws -> Invitation {
        isLoading = true
        defer { isLoading = false }
        
        // Validar email
        guard isValidEmail(toPsychologistEmail) else {
            throw InvitationError.invalidEmail
        }
        
        // Verificar se já existe convite pendente para este email
        if sentInvitations.contains(where: { 
            $0.toPsychologistEmail.lowercased() == toPsychologistEmail.lowercased() && 
            $0.status == .pending && 
            !$0.isExpired 
        }) {
            throw InvitationError.invitationAlreadyExists
        }
        
        let parameters = [
            "to_psychologist_email": toPsychologistEmail,
            "to_psychologist_name": toPsychologistName ?? "",
            "patient_name": fromPatient.fullName,
            "patient_email": fromPatient.email,
            "message": message ?? ""
        ]
        
        do {
            let response: InvitationResponse = try await networkManager.post(
                endpoint: "/invitations",
                parameters: parameters
            )
            
            let invitation = response.invitation
            
            // Adicionar à lista local
            DispatchQueue.main.async {
                self.sentInvitations.insert(invitation, at: 0)
                self.successMessage = "Convite enviado com sucesso!"
            }
            
            // Enviar notificações
            await sendInvitationNotifications(invitation: invitation)
            
            return invitation
        } catch {
            errorMessage = "Erro ao enviar convite: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Respond to Invitation
    func acceptInvitation(
        _ invitation: Invitation,
        psychologist: User,
        monthlyFee: Decimal
    ) async throws -> PatientPsychologistLink {
        isLoading = true
        defer { isLoading = false }
        
        guard invitation.canBeAccepted else {
            throw InvitationError.invitationExpired
        }
        
        let parameters = [
            "invitation_id": invitation.id.uuidString,
            "psychologist_id": psychologist.id.uuidString,
            "monthly_fee": String(describing: monthlyFee),
            "action": "accept"
        ]
        
        do {
            let response: InvitationAcceptResponse = try await networkManager.post(
                endpoint: "/invitations/\(invitation.id)/respond",
                parameters: parameters
            )
            
            let updatedInvitation = response.invitation
            let patientLink = response.patientLink
            
            // Atualizar listas locais
            DispatchQueue.main.async {
                // Atualizar convite na lista
                if let index = self.receivedInvitations.firstIndex(where: { $0.id == invitation.id }) {
                    self.receivedInvitations[index] = updatedInvitation
                }
                
                // Adicionar nova vinculação
                self.patientLinks.insert(patientLink, at: 0)
                
                self.successMessage = "Convite aceito! Paciente vinculado com sucesso."
            }
            
            // Notificar paciente sobre aceitação
            await notifyPatientInvitationAccepted(invitation: updatedInvitation, psychologist: psychologist)
            
            return patientLink
        } catch {
            errorMessage = "Erro ao aceitar convite: \(error.localizedDescription)"
            throw error
        }
    }
    
    func rejectInvitation(_ invitation: Invitation, reason: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "invitation_id": invitation.id.uuidString,
            "action": "reject",
            "reason": reason ?? ""
        ]
        
        do {
            let response: InvitationResponse = try await networkManager.post(
                endpoint: "/invitations/\(invitation.id)/respond",
                parameters: parameters
            )
            
            let updatedInvitation = response.invitation
            
            // Atualizar lista local
            DispatchQueue.main.async {
                if let index = self.receivedInvitations.firstIndex(where: { $0.id == invitation.id }) {
                    self.receivedInvitations[index] = updatedInvitation
                }
                
                self.successMessage = "Convite recusado."
            }
            
            // Notificar paciente sobre rejeição
            await notifyPatientInvitationRejected(invitation: updatedInvitation, reason: reason)
            
        } catch {
            errorMessage = "Erro ao recusar convite: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Cancel Invitation
    func cancelInvitation(_ invitation: Invitation) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard invitation.status == .pending else {
            throw InvitationError.cannotCancelInvitation
        }
        
        do {
            let response: InvitationResponse = try await networkManager.delete(
                endpoint: "/invitations/\(invitation.id)"
            )
            
            let updatedInvitation = response.invitation
            
            // Atualizar lista local
            DispatchQueue.main.async {
                if let index = self.sentInvitations.firstIndex(where: { $0.id == invitation.id }) {
                    self.sentInvitations[index] = updatedInvitation
                }
                
                self.successMessage = "Convite cancelado."
            }
            
        } catch {
            errorMessage = "Erro ao cancelar convite: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Resend Invitation
    func resendInvitation(_ invitation: Invitation) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard invitation.status == .pending && !invitation.isExpired else {
            throw InvitationError.cannotResendInvitation
        }
        
        do {
            let response: InvitationResponse = try await networkManager.post(
                endpoint: "/invitations/\(invitation.id)/resend",
                parameters: [:]
            )
            
            let updatedInvitation = response.invitation
            
            // Atualizar lista local
            DispatchQueue.main.async {
                if let index = self.sentInvitations.firstIndex(where: { $0.id == invitation.id }) {
                    self.sentInvitations[index] = updatedInvitation
                }
                
                self.successMessage = "Convite reenviado!"
            }
            
            // Reenviar notificações
            await sendInvitationNotifications(invitation: updatedInvitation)
            
        } catch {
            errorMessage = "Erro ao reenviar convite: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Patient Link Management
    func unlinkPatient(_ link: PatientPsychologistLink, reason: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "reason": reason ?? "Desvinculação solicitada"
        ]
        
        do {
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/patient-links/\(link.id)/unlink",
                parameters: parameters
            )
            
            // Remover da lista local
            DispatchQueue.main.async {
                self.patientLinks.removeAll { $0.id == link.id }
                self.successMessage = "Paciente desvinculado com sucesso."
            }
            
            // Notificar paciente sobre desvinculação
            await notifyPatientUnlinked(link: link, reason: reason)
            
        } catch {
            errorMessage = "Erro ao desvincular paciente: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateMonthlyFee(for link: PatientPsychologistLink, newFee: Decimal) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let parameters = [
            "monthly_fee": String(describing: newFee)
        ]
        
        do {
            let response: PatientLinkResponse = try await networkManager.put(
                endpoint: "/patient-links/\(link.id)",
                parameters: parameters
            )
            
            let updatedLink = response.link
            
            // Atualizar lista local
            DispatchQueue.main.async {
                if let index = self.patientLinks.firstIndex(where: { $0.id == link.id }) {
                    self.patientLinks[index] = updatedLink
                }
                
                self.successMessage = "Valor da mensalidade atualizado."
            }
            
        } catch {
            errorMessage = "Erro ao atualizar mensalidade: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Notifications
    private func sendInvitationNotifications(invitation: Invitation) async {
        // Enviar email
        await sendInvitationEmail(invitation: invitation)
        
        // Enviar SMS se disponível
        // await sendInvitationSMS(invitation: invitation)
        
        // Enviar push notification se o psicólogo já tem o app
        await sendInvitationPushNotification(invitation: invitation)
    }
    
    private func sendInvitationEmail(invitation: Invitation) async {
        let subject = InvitationTemplate.generateEmailSubject(patientName: invitation.patientName)
        let body = InvitationTemplate.generateEmailBody(
            patientName: invitation.patientName,
            patientEmail: invitation.patientEmail,
            message: invitation.message,
            invitationCode: invitation.invitationCode
        )
        
        do {
            let parameters = [
                "to": invitation.toPsychologistEmail,
                "subject": subject,
                "body": body,
                "invitation_id": invitation.id.uuidString
            ]
            
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/notifications/email",
                parameters: parameters
            )
            
            print("Email de convite enviado para: \(invitation.toPsychologistEmail)")
        } catch {
            print("Erro ao enviar email de convite: \(error)")
        }
    }
    
    private func sendInvitationPushNotification(invitation: Invitation) async {
        // Verificar se o psicólogo tem o app instalado
        do {
            let parameters = [
                "email": invitation.toPsychologistEmail,
                "title": "Novo convite no Manus Psiqueia",
                "body": "\(invitation.patientName) te convidou para ser psicólogo(a) na plataforma",
                "data": [
                    "invitation_id": invitation.id.uuidString,
                    "type": "invitation"
                ]
            ]
            
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/notifications/push",
                parameters: parameters
            )
            
            print("Push notification enviado para: \(invitation.toPsychologistEmail)")
        } catch {
            print("Erro ao enviar push notification: \(error)")
        }
    }
    
    private func notifyPatientInvitationAccepted(invitation: Invitation, psychologist: User) async {
        do {
            let parameters = [
                "patient_email": invitation.patientEmail,
                "psychologist_name": psychologist.displayName,
                "invitation_id": invitation.id.uuidString
            ]
            
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/notifications/invitation-accepted",
                parameters: parameters
            )
            
            print("Paciente notificado sobre aceitação do convite")
        } catch {
            print("Erro ao notificar paciente: \(error)")
        }
    }
    
    private func notifyPatientInvitationRejected(invitation: Invitation, reason: String?) async {
        do {
            let parameters = [
                "patient_email": invitation.patientEmail,
                "psychologist_name": invitation.toPsychologistName ?? "Psicólogo(a)",
                "reason": reason ?? "Não especificado",
                "invitation_id": invitation.id.uuidString
            ]
            
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/notifications/invitation-rejected",
                parameters: parameters
            )
            
            print("Paciente notificado sobre rejeição do convite")
        } catch {
            print("Erro ao notificar paciente: \(error)")
        }
    }
    
    private func notifyPatientUnlinked(link: PatientPsychologistLink, reason: String?) async {
        do {
            let parameters = [
                "patient_id": link.patientId.uuidString,
                "psychologist_id": link.psychologistId.uuidString,
                "reason": reason ?? "Desvinculação solicitada"
            ]
            
            let _: EmptyResponse = try await networkManager.post(
                endpoint: "/notifications/patient-unlinked",
                parameters: parameters
            )
            
            print("Paciente notificado sobre desvinculação")
        } catch {
            print("Erro ao notificar paciente sobre desvinculação: \(error)")
        }
    }
    
    // MARK: - Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Analytics
    func getInvitationAnalytics(period: AnalyticsPeriod = .month) async throws -> InvitationAnalytics {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: InvitationAnalyticsResponse = try await networkManager.get(
                endpoint: "/analytics/invitations?period=\(period.rawValue)"
            )
            
            return response.analytics
        } catch {
            errorMessage = "Erro ao carregar analytics: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Utility Methods
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func getActivePatientLinks() -> [PatientPsychologistLink] {
        return patientLinks.filter { $0.isActive }
    }
    
    func getInactivePatientLinks() -> [PatientPsychologistLink] {
        return patientLinks.filter { !$0.isActive }
    }
    
    func getPendingInvitations() -> [Invitation] {
        return sentInvitations.filter { $0.status == .pending && !$0.isExpired }
    }
    
    func getExpiredInvitations() -> [Invitation] {
        return sentInvitations.filter { $0.isExpired || $0.status == .expired }
    }
    
    func getTotalEarningsFromLinks() -> Decimal {
        return patientLinks.reduce(0) { $0 + $1.totalPaid }
    }
    
    func getMonthlyRecurringRevenue() -> Decimal {
        return getActivePatientLinks().reduce(0) { $0 + $1.monthlyFee }
    }
}

// MARK: - Response Models
struct InvitationResponse: Codable {
    let invitation: Invitation
}

struct InvitationListResponse: Codable {
    let invitations: [Invitation]
    let total: Int
    let page: Int
    let limit: Int
}

struct InvitationAcceptResponse: Codable {
    let invitation: Invitation
    let patientLink: PatientPsychologistLink
}

struct PatientLinksResponse: Codable {
    let links: [PatientPsychologistLink]
    let total: Int
}

struct PatientLinkResponse: Codable {
    let link: PatientPsychologistLink
}

struct InvitationAnalyticsResponse: Codable {
    let analytics: InvitationAnalytics
}

struct EmptyResponse: Codable {
    // Resposta vazia para endpoints que não retornam dados
}

// MARK: - Invitation Errors
enum InvitationError: LocalizedError {
    case invalidEmail
    case invitationAlreadyExists
    case invitationExpired
    case cannotCancelInvitation
    case cannotResendInvitation
    case psychologistNotFound
    case patientNotFound
    case linkAlreadyExists
    case linkNotFound
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Email inválido"
        case .invitationAlreadyExists:
            return "Já existe um convite pendente para este email"
        case .invitationExpired:
            return "Este convite expirou"
        case .cannotCancelInvitation:
            return "Não é possível cancelar este convite"
        case .cannotResendInvitation:
            return "Não é possível reenviar este convite"
        case .psychologistNotFound:
            return "Psicólogo não encontrado"
        case .patientNotFound:
            return "Paciente não encontrado"
        case .linkAlreadyExists:
            return "Paciente já está vinculado a este psicólogo"
        case .linkNotFound:
            return "Vinculação não encontrada"
        case .insufficientPermissions:
            return "Permissões insuficientes"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let invitationReceived = Notification.Name("invitationReceived")
    static let invitationAccepted = Notification.Name("invitationAccepted")
    static let patientLinked = Notification.Name("patientLinked")
    static let patientUnlinked = Notification.Name("patientUnlinked")
}
