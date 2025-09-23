//
//  User.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation

// MARK: - User Model
public struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let userType: UserType
    let profileImageURL: String?
    let phone: String?
    let dateOfBirth: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Relacionamentos
    var psychologistProfile: PsychologistProfile?
    var patientProfile: PatientProfile?
    var linkedPsychologist: User? // Para pacientes
    var linkedPatients: [User]? // Para psicólogos
    
    // Computed Properties
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    var displayName: String {
        return userType == .psychologist ? "Dr(a). \(fullName)" : fullName
    }
    
    var canAccessPlatform: Bool {
        switch userType {
        case .psychologist:
            return psychologistProfile?.hasActiveSubscription ?? false
        case .patient:
            return linkedPsychologist != nil
        }
    }
    
    init(
        id: UUID = UUID(),
        email: String,
        firstName: String,
        lastName: String,
        userType: UserType,
        profileImageURL: String? = nil,
        phone: String? = nil,
        dateOfBirth: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.userType = userType
        self.profileImageURL = profileImageURL
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Type
public enum UserType: String, CaseIterable, Codable {
    case psychologist = "psychologist"
    case patient = "patient"
    
    var displayName: String {
        switch self {
        case .psychologist:
            return "Psicólogo(a)"
        case .patient:
            return "Paciente"
        }
    }
    
    var description: String {
        switch self {
        case .psychologist:
            return "Profissional de psicologia que oferece atendimento na plataforma"
        case .patient:
            return "Pessoa que busca atendimento psicológico"
        }
    }
    
    var icon: String {
        switch self {
        case .psychologist:
            return "stethoscope"
        case .patient:
            return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .psychologist:
            return Color(red: 0.4, green: 0.2, blue: 0.8)
        case .patient:
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        }
    }
}

// MARK: - Psychologist Profile
public struct PsychologistProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let crpNumber: String
    let specializations: [Specialization]
    let bio: String?
    let experienceYears: Int
    let consultationFee: Decimal
    let availableHours: [AvailableHour]
    let hasActiveSubscription: Bool
    let subscriptionExpiresAt: Date?
    let stripeCustomerId: String?
    let stripeAccountId: String? // Para receber pagamentos
    let totalEarnings: Decimal
    let monthlyEarnings: Decimal
    let pendingWithdrawal: Decimal
    let rating: Double
    let totalConsultations: Int
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        crpNumber: String,
        specializations: [Specialization] = [],
        bio: String? = nil,
        experienceYears: Int = 0,
        consultationFee: Decimal = 150.00,
        availableHours: [AvailableHour] = [],
        hasActiveSubscription: Bool = false,
        subscriptionExpiresAt: Date? = nil,
        stripeCustomerId: String? = nil,
        stripeAccountId: String? = nil,
        totalEarnings: Decimal = 0,
        monthlyEarnings: Decimal = 0,
        pendingWithdrawal: Decimal = 0,
        rating: Double = 0.0,
        totalConsultations: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.crpNumber = crpNumber
        self.specializations = specializations
        self.bio = bio
        self.experienceYears = experienceYears
        self.consultationFee = consultationFee
        self.availableHours = availableHours
        self.hasActiveSubscription = hasActiveSubscription
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.stripeCustomerId = stripeCustomerId
        self.stripeAccountId = stripeAccountId
        self.totalEarnings = totalEarnings
        self.monthlyEarnings = monthlyEarnings
        self.pendingWithdrawal = pendingWithdrawal
        self.rating = rating
        self.totalConsultations = totalConsultations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var formattedConsultationFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: consultationFee as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var formattedTotalEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: totalEarnings as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    var subscriptionStatus: SubscriptionStatus {
        if !hasActiveSubscription {
            return .inactive
        }
        
        guard let expiresAt = subscriptionExpiresAt else {
            return .active
        }
        
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        
        if daysUntilExpiration <= 0 {
            return .expired
        } else if daysUntilExpiration <= 7 {
            return .expiringSoon
        } else {
            return .active
        }
    }
}

// MARK: - Patient Profile
public struct PatientProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let linkedPsychologistId: UUID?
    let emergencyContactName: String?
    let emergencyContactPhone: String?
    let medicalHistory: String?
    let currentMedications: [String]
    let therapyGoals: [String]
    let hasActivePayment: Bool
    let paymentExpiresAt: Date?
    let stripeCustomerId: String?
    let monthlyFee: Decimal?
    let totalPaid: Decimal
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        linkedPsychologistId: UUID? = nil,
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        medicalHistory: String? = nil,
        currentMedications: [String] = [],
        therapyGoals: [String] = [],
        hasActivePayment: Bool = false,
        paymentExpiresAt: Date? = nil,
        stripeCustomerId: String? = nil,
        monthlyFee: Decimal? = nil,
        totalPaid: Decimal = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.linkedPsychologistId = linkedPsychologistId
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.medicalHistory = medicalHistory
        self.currentMedications = currentMedications
        self.therapyGoals = therapyGoals
        self.hasActivePayment = hasActivePayment
        self.paymentExpiresAt = paymentExpiresAt
        self.stripeCustomerId = stripeCustomerId
        self.monthlyFee = monthlyFee
        self.totalPaid = totalPaid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var paymentStatus: PaymentStatus {
        if !hasActivePayment {
            return .inactive
        }
        
        guard let expiresAt = paymentExpiresAt else {
            return .active
        }
        
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        
        if daysUntilExpiration <= 0 {
            return .expired
        } else if daysUntilExpiration <= 3 {
            return .expiringSoon
        } else {
            return .active
        }
    }
    
    var formattedMonthlyFee: String {
        guard let fee = monthlyFee else { return "Não definido" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: fee as NSDecimalNumber) ?? "R$ 0,00"
    }
}

// MARK: - Supporting Enums
public enum Specialization: String, CaseIterable, Codable {
    case clinicalPsychology = "clinical_psychology"
    case cognitiveTherapy = "cognitive_therapy"
    case psychoanalysis = "psychoanalysis"
    case familyTherapy = "family_therapy"
    case childPsychology = "child_psychology"
    case neuropsychology = "neuropsychology"
    case organizationalPsychology = "organizational_psychology"
    case sportPsychology = "sport_psychology"
    case healthPsychology = "health_psychology"
    case forensicPsychology = "forensic_psychology"
    
    var displayName: String {
        switch self {
        case .clinicalPsychology:
            return "Psicologia Clínica"
        case .cognitiveTherapy:
            return "Terapia Cognitiva"
        case .psychoanalysis:
            return "Psicanálise"
        case .familyTherapy:
            return "Terapia Familiar"
        case .childPsychology:
            return "Psicologia Infantil"
        case .neuropsychology:
            return "Neuropsicologia"
        case .organizationalPsychology:
            return "Psicologia Organizacional"
        case .sportPsychology:
            return "Psicologia do Esporte"
        case .healthPsychology:
            return "Psicologia da Saúde"
        case .forensicPsychology:
            return "Psicologia Forense"
        }
    }
    
    var icon: String {
        switch self {
        case .clinicalPsychology:
            return "heart.text.square"
        case .cognitiveTherapy:
            return "brain.head.profile"
        case .psychoanalysis:
            return "quote.bubble"
        case .familyTherapy:
            return "person.3"
        case .childPsychology:
            return "figure.child"
        case .neuropsychology:
            return "brain"
        case .organizationalPsychology:
            return "building.2"
        case .sportPsychology:
            return "figure.run"
        case .healthPsychology:
            return "cross.case"
        case .forensicPsychology:
            return "scale.3d"
        }
    }
}

public struct AvailableHour: Identifiable, Codable, Hashable {
    let id: UUID
    let dayOfWeek: Int // 1 = Segunda, 7 = Domingo
    let startTime: String // "09:00"
    let endTime: String // "18:00"
    let isAvailable: Bool
    
    init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        startTime: String,
        endTime: String,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }
    
    var dayName: String {
        let days = ["", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
        return days[dayOfWeek]
    }
}

public enum SubscriptionStatus: String, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case expired = "expired"
    case expiringSoon = "expiring_soon"
    
    var displayName: String {
        switch self {
        case .active:
            return "Ativa"
        case .inactive:
            return "Inativa"
        case .expired:
            return "Expirada"
        case .expiringSoon:
            return "Expirando em breve"
        }
    }
    
    var color: Color {
        switch self {
        case .active:
            return .green
        case .inactive:
            return .gray
        case .expired:
            return .red
        case .expiringSoon:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .active:
            return "checkmark.circle.fill"
        case .inactive:
            return "xmark.circle.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.fill"
        }
    }
}

public enum PaymentStatus: String, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case expired = "expired"
    case expiringSoon = "expiring_soon"
    
    var displayName: String {
        switch self {
        case .active:
            return "Ativo"
        case .inactive:
            return "Inativo"
        case .expired:
            return "Expirado"
        case .expiringSoon:
            return "Expirando em breve"
        }
    }
    
    var color: Color {
        switch self {
        case .active:
            return .green
        case .inactive:
            return .gray
        case .expired:
            return .red
        case .expiringSoon:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .active:
            return "creditcard.fill"
        case .inactive:
            return "creditcard"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.fill"
        }
    }
}

// MARK: - User Extensions
extension User {
    static let mockPsychologist = User(
        email: "dr.silva@email.com",
        firstName: "Ana",
        lastName: "Silva",
        userType: .psychologist,
        phone: "(11) 99999-9999"
    )
    
    static let mockPatient = User(
        email: "joao@email.com",
        firstName: "João",
        lastName: "Santos",
        userType: .patient,
        phone: "(11) 88888-8888"
    )
}

extension PsychologistProfile {
    static let mock = PsychologistProfile(
        userId: UUID(),
        crpNumber: "12345/SP",
        specializations: [.clinicalPsychology, .cognitiveTherapy],
        bio: "Psicóloga clínica com mais de 10 anos de experiência em terapia cognitivo-comportamental.",
        experienceYears: 10,
        consultationFee: 180.00,
        hasActiveSubscription: true,
        subscriptionExpiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        totalEarnings: 15000.00,
        monthlyEarnings: 3500.00,
        pendingWithdrawal: 1200.00,
        rating: 4.8,
        totalConsultations: 150
    )
}

extension PatientProfile {
    static let mock = PatientProfile(
        userId: UUID(),
        linkedPsychologistId: UUID(),
        emergencyContactName: "Maria Santos",
        emergencyContactPhone: "(11) 77777-7777",
        therapyGoals: ["Reduzir ansiedade", "Melhorar autoestima"],
        hasActivePayment: true,
        paymentExpiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
        monthlyFee: 180.00,
        totalPaid: 720.00
    )
}
