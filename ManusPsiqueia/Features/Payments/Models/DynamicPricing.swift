//
//  DynamicPricing.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Dynamic Pricing Models
struct PricingTier: Identifiable, Codable {
    let id = UUID()
    let name: String
    let minPatients: Int
    let maxPatients: Int?
    let pricePerPatient: Int // Em centavos
    let basePrice: Int // Taxa base em centavos
    let features: [String]
    let isPopular: Bool
    let discount: Double // Desconto em porcentagem
    
    var displayName: String {
        if let maxPatients = maxPatients {
            return "\(minPatients) - \(maxPatients) pacientes"
        } else {
            return "\(minPatients)+ pacientes"
        }
    }
    
    var totalPrice: Int {
        let discountedPrice = Double(basePrice + (pricePerPatient * minPatients)) * (1 - discount)
        return Int(discountedPrice)
    }
    
    func calculatePrice(for patientCount: Int) -> Int {
        let effectivePatients = max(minPatients, patientCount)
        let finalPatients = maxPatients != nil ? min(effectivePatients, maxPatients!) : effectivePatients
        let discountedPrice = Double(basePrice + (pricePerPatient * finalPatients)) * (1 - discount)
        return Int(discountedPrice)
    }
}

struct CustomPlan: Identifiable, Codable {
    let id = UUID()
    let psychologistId: String
    let patientCount: Int
    let selectedFeatures: [PlanFeature]
    let monthlyPrice: Int
    let annualPrice: Int
    let createdAt: Date
    let isActive: Bool
    
    var savings: Int {
        return (monthlyPrice * 12) - annualPrice
    }
    
    var savingsPercentage: Double {
        let annualMonthly = monthlyPrice * 12
        return Double(annualMonthly - annualPrice) / Double(annualMonthly) * 100
    }
}

struct PlanFeature: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let pricePerPatient: Int // Custo adicional por paciente
    let basePrice: Int // Taxa fixa
    let category: FeatureCategory
    let isEssential: Bool
    
    enum FeatureCategory: String, CaseIterable, Codable {
        case basic = "Básico"
        case analytics = "Analytics"
        case ai = "Inteligência Artificial"
        case communication = "Comunicação"
        case integration = "Integrações"
        case premium = "Premium"
    }
}

// MARK: - Pricing Calculator
@MainActor
class DynamicPricingCalculator: ObservableObject {
    @Published var selectedPatientCount: Int = 5
    @Published var selectedFeatures: Set<PlanFeature> = []
    @Published var billingCycle: BillingCycle = .monthly
    @Published var calculatedPrice: Int = 0
    @Published var recommendedTier: PricingTier?
    
    // Tiers de precificação
    let pricingTiers: [PricingTier] = [
        PricingTier(
            name: "Iniciante",
            minPatients: 1,
            maxPatients: 10,
            pricePerPatient: 890, // R$ 8,90 por paciente
            basePrice: 2990, // R$ 29,90 taxa base
            features: [
                "Até 10 pacientes ativos",
                "Agendamento básico",
                "Prontuário digital",
                "Chat seguro",
                "Relatórios básicos"
            ],
            isPopular: false,
            discount: 0.0
        ),
        
        PricingTier(
            name: "Profissional",
            minPatients: 11,
            maxPatients: 30,
            pricePerPatient: 690, // R$ 6,90 por paciente
            basePrice: 4990, // R$ 49,90 taxa base
            features: [
                "Até 30 pacientes ativos",
                "Agendamento avançado",
                "Prontuário completo",
                "Videochamadas ilimitadas",
                "Analytics básico",
                "Lembretes automáticos",
                "Backup automático"
            ],
            isPopular: true,
            discount: 0.15 // 15% de desconto
        ),
        
        PricingTier(
            name: "Clínica",
            minPatients: 31,
            maxPatients: 100,
            pricePerPatient: 490, // R$ 4,90 por paciente
            basePrice: 9990, // R$ 99,90 taxa base
            features: [
                "Até 100 pacientes ativos",
                "Multi-profissionais",
                "Dashboard avançado",
                "IA para insights",
                "Relatórios personalizados",
                "API de integração",
                "Suporte prioritário",
                "White-label opcional"
            ],
            isPopular: false,
            discount: 0.25 // 25% de desconto
        ),
        
        PricingTier(
            name: "Enterprise",
            minPatients: 101,
            maxPatients: nil,
            pricePerPatient: 290, // R$ 2,90 por paciente
            basePrice: 19990, // R$ 199,90 taxa base
            features: [
                "Pacientes ilimitados",
                "Múltiplas clínicas",
                "IA avançada personalizada",
                "Analytics preditivo",
                "Integrações customizadas",
                "Suporte 24/7",
                "Gerente de conta dedicado",
                "SLA garantido",
                "Compliance personalizado"
            ],
            isPopular: false,
            discount: 0.35 // 35% de desconto
        )
    ]
    
    // Features disponíveis
    let availableFeatures: [PlanFeature] = [
        // Básico
        PlanFeature(
            name: "Prontuário Digital",
            description: "Sistema completo de prontuários eletrônicos",
            icon: "doc.text.fill",
            pricePerPatient: 0,
            basePrice: 0,
            category: .basic,
            isEssential: true
        ),
        
        PlanFeature(
            name: "Chat Seguro",
            description: "Comunicação criptografada com pacientes",
            icon: "message.fill",
            pricePerPatient: 0,
            basePrice: 0,
            category: .basic,
            isEssential: true
        ),
        
        // Analytics
        PlanFeature(
            name: "Relatórios Avançados",
            description: "Analytics detalhado de progresso dos pacientes",
            icon: "chart.bar.fill",
            pricePerPatient: 190, // R$ 1,90 por paciente
            basePrice: 990, // R$ 9,90 base
            category: .analytics,
            isEssential: false
        ),
        
        PlanFeature(
            name: "Dashboard Executivo",
            description: "Métricas de negócio e performance",
            icon: "speedometer",
            pricePerPatient: 290, // R$ 2,90 por paciente
            basePrice: 1990, // R$ 19,90 base
            category: .analytics,
            isEssential: false
        ),
        
        // IA
        PlanFeature(
            name: "Insights de IA",
            description: "Análise inteligente dos diários dos pacientes",
            icon: "brain.head.profile",
            pricePerPatient: 490, // R$ 4,90 por paciente
            basePrice: 2990, // R$ 29,90 base
            category: .ai,
            isEssential: false
        ),
        
        PlanFeature(
            name: "Detecção de Risco",
            description: "IA para identificar pacientes em risco",
            icon: "exclamationmark.shield.fill",
            pricePerPatient: 690, // R$ 6,90 por paciente
            basePrice: 4990, // R$ 49,90 base
            category: .ai,
            isEssential: false
        ),
        
        // Comunicação
        PlanFeature(
            name: "Videochamadas HD",
            description: "Consultas por vídeo em alta definição",
            icon: "video.fill",
            pricePerPatient: 390, // R$ 3,90 por paciente
            basePrice: 1990, // R$ 19,90 base
            category: .communication,
            isEssential: false
        ),
        
        PlanFeature(
            name: "Lembretes Inteligentes",
            description: "Sistema automatizado de lembretes",
            icon: "bell.badge.fill",
            pricePerPatient: 90, // R$ 0,90 por paciente
            basePrice: 490, // R$ 4,90 base
            category: .communication,
            isEssential: false
        ),
        
        // Integrações
        PlanFeature(
            name: "API Personalizada",
            description: "Integração com sistemas externos",
            icon: "link",
            pricePerPatient: 590, // R$ 5,90 por paciente
            basePrice: 9990, // R$ 99,90 base
            category: .integration,
            isEssential: false
        ),
        
        // Premium
        PlanFeature(
            name: "White Label",
            description: "Plataforma com sua marca",
            icon: "paintbrush.fill",
            pricePerPatient: 990, // R$ 9,90 por paciente
            basePrice: 19990, // R$ 199,90 base
            category: .premium,
            isEssential: false
        ),
        
        PlanFeature(
            name: "Suporte Prioritário",
            description: "Atendimento 24/7 com prioridade",
            icon: "headphones",
            pricePerPatient: 290, // R$ 2,90 por paciente
            basePrice: 4990, // R$ 49,90 base
            category: .premium,
            isEssential: false
        )
    ]
    
    enum BillingCycle: String, CaseIterable {
        case monthly = "Mensal"
        case annual = "Anual"
        
        var discount: Double {
            switch self {
            case .monthly: return 0.0
            case .annual: return 0.20 // 20% de desconto anual
            }
        }
        
        var multiplier: Int {
            switch self {
            case .monthly: return 1
            case .annual: return 12
            }
        }
    }
    
    init() {
        calculatePrice()
        findRecommendedTier()
    }
    
    func calculatePrice() {
        // Calcular preço base do tier recomendado
        let tier = findBestTier(for: selectedPatientCount)
        let basePrice = tier.calculatePrice(for: selectedPatientCount)
        
        // Adicionar features selecionadas
        let featuresPrice = selectedFeatures.reduce(0) { total, feature in
            total + feature.basePrice + (feature.pricePerPatient * selectedPatientCount)
        }
        
        let totalMonthly = basePrice + featuresPrice
        
        // Aplicar desconto do ciclo de cobrança
        let discountedPrice = Double(totalMonthly) * (1 - billingCycle.discount)
        
        calculatedPrice = Int(discountedPrice)
    }
    
    func findBestTier(for patientCount: Int) -> PricingTier {
        return pricingTiers.first { tier in
            patientCount >= tier.minPatients && (tier.maxPatients == nil || patientCount <= tier.maxPatients!)
        } ?? pricingTiers.last!
    }
    
    func findRecommendedTier() {
        recommendedTier = findBestTier(for: selectedPatientCount)
    }
    
    func updatePatientCount(_ count: Int) {
        selectedPatientCount = max(1, count)
        calculatePrice()
        findRecommendedTier()
    }
    
    func toggleFeature(_ feature: PlanFeature) {
        if selectedFeatures.contains(feature) {
            selectedFeatures.remove(feature)
        } else {
            selectedFeatures.insert(feature)
        }
        calculatePrice()
    }
    
    func setBillingCycle(_ cycle: BillingCycle) {
        billingCycle = cycle
        calculatePrice()
    }
    
    func getEstimatedROI() -> ROICalculation {
        // Calcular ROI baseado no valor médio de consulta (R$ 150)
        let averageSessionPrice = 15000 // R$ 150 em centavos
        let sessionsPerPatientPerMonth = 4 // Média de 4 sessões por mês
        
        let monthlyRevenue = selectedPatientCount * sessionsPerPatientPerMonth * averageSessionPrice
        let monthlyCost = calculatedPrice
        let monthlyProfit = monthlyRevenue - monthlyCost
        
        let roi = Double(monthlyProfit) / Double(monthlyCost) * 100
        
        return ROICalculation(
            monthlyRevenue: monthlyRevenue,
            monthlyCost: monthlyCost,
            monthlyProfit: monthlyProfit,
            roi: roi,
            breakEvenPatients: Int(ceil(Double(monthlyCost) / Double(sessionsPerPatientPerMonth * averageSessionPrice)))
        )
    }
    
    func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        
        let value = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

struct ROICalculation {
    let monthlyRevenue: Int
    let monthlyCost: Int
    let monthlyProfit: Int
    let roi: Double
    let breakEvenPatients: Int
}

// MARK: - Usage Tracking
struct UsageMetrics: Codable {
    let psychologistId: String
    let currentPatients: Int
    let maxPatients: Int
    let activeFeatures: [String]
    let monthlyUsage: [String: Int] // Feature usage counts
    let lastUpdated: Date
    
    var utilizationPercentage: Double {
        return Double(currentPatients) / Double(maxPatients) * 100
    }
    
    var needsUpgrade: Bool {
        return utilizationPercentage > 85.0
    }
    
    var suggestedUpgrade: PricingTier? {
        // Logic to suggest next tier based on usage
        return nil
    }
}

// MARK: - Plan Comparison
struct PlanComparison {
    let currentPlan: CustomPlan
    let suggestedPlan: CustomPlan
    
    var monthlySavings: Int {
        return currentPlan.monthlyPrice - suggestedPlan.monthlyPrice
    }
    
    var annualSavings: Int {
        return currentPlan.annualPrice - suggestedPlan.annualPrice
    }
    
    var additionalFeatures: [PlanFeature] {
        let currentFeatureIds = Set(currentPlan.selectedFeatures.map { $0.id })
        return suggestedPlan.selectedFeatures.filter { !currentFeatureIds.contains($0.id) }
    }
}
