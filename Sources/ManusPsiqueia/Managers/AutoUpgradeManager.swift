//
//  AutoUpgradeManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AutoUpgradeManager: ObservableObject {
    @Published var currentUsage: UsageMetrics?
    @Published var upgradeRecommendations: [UpgradeRecommendation] = []
    @Published var showingUpgradeAlert = false
    @Published var pendingUpgrade: UpgradeRecommendation?
    @Published var isMonitoring = false
    
    private var cancellables = Set<AnyCancellable>()
    private let usageThreshold: Double = 85.0 // 85% usage triggers upgrade suggestion
    private let criticalThreshold: Double = 95.0 // 95% usage triggers automatic upgrade
    
    static let shared = AutoUpgradeManager()
    
    private init() {
        startUsageMonitoring()
    }
    
    // MARK: - Usage Monitoring
    func startUsageMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Monitor usage every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkUsageAndRecommendUpgrades()
                }
            }
            .store(in: &cancellables)
        
        // Initial check
        Task {
            await checkUsageAndRecommendUpgrades()
        }
    }
    
    func stopUsageMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
    }
    
    private func checkUsageAndRecommendUpgrades() async {
        // Simulate fetching current usage from backend
        let usage = await fetchCurrentUsage()
        currentUsage = usage
        
        // Generate recommendations based on usage
        let recommendations = generateUpgradeRecommendations(for: usage)
        upgradeRecommendations = recommendations
        
        // Check if automatic upgrade is needed
        if usage.utilizationPercentage >= criticalThreshold {
            await handleCriticalUsage(usage)
        } else if usage.utilizationPercentage >= usageThreshold {
            handleHighUsage(recommendations)
        }
    }
    
    private func fetchCurrentUsage() async -> UsageMetrics {
        // Simulate API call to fetch usage metrics
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Mock data - in real app, this would come from your backend
        return UsageMetrics(
            psychologistId: "psych_123",
            currentPatients: 28,
            maxPatients: 30,
            activeFeatures: ["basic", "analytics"],
            monthlyUsage: [
                "sessions": 112,
                "reports_generated": 45,
                "ai_insights": 23
            ],
            lastUpdated: Date()
        )
    }
    
    // MARK: - Upgrade Recommendations
    private func generateUpgradeRecommendations(for usage: UsageMetrics) -> [UpgradeRecommendation] {
        var recommendations: [UpgradeRecommendation] = []
        
        // Patient capacity recommendation
        if usage.utilizationPercentage > 80 {
            let nextTier = findNextTier(for: usage.currentPatients)
            recommendations.append(
                UpgradeRecommendation(
                    type: .patientCapacity,
                    title: "Aumente sua Capacidade",
                    description: "Você está usando \(Int(usage.utilizationPercentage))% da sua capacidade. Considere fazer upgrade para o plano \(nextTier.name).",
                    currentTier: findCurrentTier(for: usage.maxPatients),
                    suggestedTier: nextTier,
                    urgency: usage.utilizationPercentage > 90 ? .high : .medium,
                    estimatedSavings: calculatePotentialSavings(currentPatients: usage.currentPatients, newTier: nextTier),
                    benefits: [
                        "Capacidade para \(nextTier.maxPatients ?? 999) pacientes",
                        "Recursos adicionais incluídos",
                        "Melhor custo por paciente",
                        "Sem interrupção do serviço"
                    ]
                )
            )
        }
        
        // Feature usage recommendations
        if usage.monthlyUsage["ai_insights"] ?? 0 > 20 && !usage.activeFeatures.contains("ai_premium") {
            recommendations.append(
                UpgradeRecommendation(
                    type: .featureUpgrade,
                    title: "Upgrade IA Premium",
                    description: "Você está usando muito os insights de IA. O plano premium oferece análises mais avançadas.",
                    currentTier: findCurrentTier(for: usage.maxPatients),
                    suggestedTier: findCurrentTier(for: usage.maxPatients), // Same tier, different features
                    urgency: .low,
                    estimatedSavings: 0,
                    benefits: [
                        "Insights de IA ilimitados",
                        "Análise preditiva avançada",
                        "Relatórios personalizados",
                        "Detecção de risco aprimorada"
                    ]
                )
            )
        }
        
        // Performance optimization
        if usage.monthlyUsage["sessions"] ?? 0 > 100 {
            recommendations.append(
                UpgradeRecommendation(
                    type: .performance,
                    title: "Otimização de Performance",
                    description: "Com \(usage.monthlyUsage["sessions"] ?? 0) sessões mensais, recursos premium melhorariam sua eficiência.",
                    currentTier: findCurrentTier(for: usage.maxPatients),
                    suggestedTier: findNextTier(for: usage.currentPatients),
                    urgency: .medium,
                    estimatedSavings: calculateTimeBasedSavings(sessions: usage.monthlyUsage["sessions"] ?? 0),
                    benefits: [
                        "Agendamento automático",
                        "Lembretes inteligentes",
                        "Relatórios automatizados",
                        "Dashboard executivo"
                    ]
                )
            )
        }
        
        return recommendations.sorted { $0.urgency.rawValue > $1.urgency.rawValue }
    }
    
    private func findCurrentTier(for maxPatients: Int) -> PricingTier {
        let calculator = DynamicPricingCalculator()
        return calculator.findBestTier(for: maxPatients)
    }
    
    private func findNextTier(for currentPatients: Int) -> PricingTier {
        let calculator = DynamicPricingCalculator()
        let tiers = calculator.pricingTiers.sorted { $0.minPatients < $1.minPatients }
        
        for tier in tiers {
            if currentPatients < tier.minPatients || (tier.maxPatients != nil && currentPatients < tier.maxPatients!) {
                return tier
            }
        }
        
        return tiers.last! // Enterprise tier
    }
    
    private func calculatePotentialSavings(currentPatients: Int, newTier: PricingTier) -> Int {
        let currentCostPerPatient = 8990 // Average cost per patient in current tier
        let newCostPerPatient = newTier.pricePerPatient
        
        if newCostPerPatient < currentCostPerPatient {
            return (currentCostPerPatient - newCostPerPatient) * currentPatients
        }
        
        return 0
    }
    
    private func calculateTimeBasedSavings(sessions: Int) -> Int {
        // Estimate time savings from automation features
        let timePerSession = 15 // minutes saved per session
        let hourlyRate = 15000 // R$ 150 per hour in cents
        let totalMinutesSaved = sessions * timePerSession
        let totalHoursSaved = totalMinutesSaved / 60
        
        return totalHoursSaved * hourlyRate
    }
    
    // MARK: - Upgrade Handling
    private func handleHighUsage(_ recommendations: [UpgradeRecommendation]) {
        guard let topRecommendation = recommendations.first else { return }
        
        pendingUpgrade = topRecommendation
        showingUpgradeAlert = true
    }
    
    private func handleCriticalUsage(_ usage: UsageMetrics) async {
        // For critical usage, we might want to automatically upgrade
        // or at least show a more urgent notification
        
        let nextTier = findNextTier(for: usage.currentPatients)
        let criticalRecommendation = UpgradeRecommendation(
            type: .automatic,
            title: "Upgrade Crítico Necessário",
            description: "Você atingiu 95% da capacidade. Para evitar interrupções, recomendamos upgrade imediato.",
            currentTier: findCurrentTier(for: usage.maxPatients),
            suggestedTier: nextTier,
            urgency: .critical,
            estimatedSavings: 0,
            benefits: [
                "Evita interrupção do serviço",
                "Capacidade expandida imediatamente",
                "Recursos premium incluídos",
                "Suporte prioritário"
            ]
        )
        
        pendingUpgrade = criticalRecommendation
        showingUpgradeAlert = true
        
        // Optionally, trigger automatic upgrade after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { // 5 minutes
            if self.showingUpgradeAlert {
                Task {
                    await self.performAutomaticUpgrade(criticalRecommendation)
                }
            }
        }
    }
    
    func acceptUpgradeRecommendation(_ recommendation: UpgradeRecommendation) async {
        showingUpgradeAlert = false
        pendingUpgrade = nil
        
        // Integrate with Stripe to process upgrade
        await processUpgrade(recommendation)
    }
    
    func dismissUpgradeRecommendation() {
        showingUpgradeAlert = false
        pendingUpgrade = nil
    }
    
    private func performAutomaticUpgrade(_ recommendation: UpgradeRecommendation) async {
        // Only perform automatic upgrade for critical situations
        // and with user's prior consent (stored in preferences)
        
        guard recommendation.urgency == .critical else { return }
        
        // Check if user has enabled automatic upgrades
        let hasAutoUpgradeEnabled = UserDefaults.standard.bool(forKey: "auto_upgrade_enabled")
        guard hasAutoUpgradeEnabled else { return }
        
        await processUpgrade(recommendation)
    }
    
    private func processUpgrade(_ recommendation: UpgradeRecommendation) async {
        // Integrate with StripePaymentSheetManager to process the upgrade
        let stripeManager = StripePaymentSheetManager.shared
        
        do {
            // Calculate new subscription amount
            let newAmount = recommendation.suggestedTier.calculatePrice(for: currentUsage?.currentPatients ?? 10)
            
            // Process upgrade through Stripe
            // This would typically involve:
            // 1. Updating the subscription in Stripe
            // 2. Prorating the charges
            // 3. Updating user's plan in your backend
            
            print("Processing upgrade to \(recommendation.suggestedTier.name) for \(newAmount) cents")
            
            // Update local usage metrics
            if var usage = currentUsage {
                usage.maxPatients = recommendation.suggestedTier.maxPatients ?? 999
                currentUsage = usage
            }
            
            // Show success notification
            NotificationCenter.default.post(
                name: NSNotification.Name("UpgradeCompleted"),
                object: recommendation
            )
            
        } catch {
            print("Upgrade failed: \(error)")
            
            // Show error notification
            NotificationCenter.default.post(
                name: NSNotification.Name("UpgradeFailed"),
                object: error
            )
        }
    }
    
    // MARK: - Analytics
    func getUpgradeAnalytics() -> UpgradeAnalytics {
        return UpgradeAnalytics(
            totalRecommendations: upgradeRecommendations.count,
            highPriorityRecommendations: upgradeRecommendations.filter { $0.urgency == .high || $0.urgency == .critical }.count,
            potentialMonthlySavings: upgradeRecommendations.reduce(0) { $0 + $1.estimatedSavings },
            currentUtilization: currentUsage?.utilizationPercentage ?? 0,
            recommendedActions: upgradeRecommendations.map { $0.type }
        )
    }
    
    func generateUpgradeReport() -> UpgradeReport {
        guard let usage = currentUsage else {
            return UpgradeReport(
                generatedAt: Date(),
                psychologistId: "",
                currentUsage: UsageMetrics(
                    psychologistId: "",
                    currentPatients: 0,
                    maxPatients: 0,
                    activeFeatures: [],
                    monthlyUsage: [:],
                    lastUpdated: Date()
                ),
                recommendations: [],
                projectedGrowth: nil,
                estimatedROI: 0
            )
        }
        
        return UpgradeReport(
            generatedAt: Date(),
            psychologistId: usage.psychologistId,
            currentUsage: usage,
            recommendations: upgradeRecommendations,
            projectedGrowth: calculateProjectedGrowth(usage),
            estimatedROI: calculateUpgradeROI(usage)
        )
    }
    
    private func calculateProjectedGrowth(_ usage: UsageMetrics) -> ProjectedGrowth {
        // Simple growth projection based on current usage trends
        let currentGrowthRate = 0.15 // 15% monthly growth assumption
        
        return ProjectedGrowth(
            timeframe: .threeMonths,
            projectedPatients: Int(Double(usage.currentPatients) * (1 + currentGrowthRate * 3)),
            confidenceLevel: 0.75,
            factors: [
                "Utilização atual alta",
                "Tendência de crescimento do mercado",
                "Recursos de IA atraem mais pacientes"
            ]
        )
    }
    
    private func calculateUpgradeROI(_ usage: UsageMetrics) -> Double {
        // Calculate ROI of upgrading based on efficiency gains and cost savings
        let efficiencyGains = Double(usage.monthlyUsage["sessions"] ?? 0) * 0.20 // 20% efficiency gain
        let costPerHour = 150.0 // R$ 150 per hour
        let monthlySavings = efficiencyGains * costPerHour
        
        let upgradeCost = Double(upgradeRecommendations.first?.suggestedTier.totalPrice ?? 0) / 100.0
        
        return (monthlySavings / upgradeCost) * 100
    }
}

// MARK: - Supporting Models
struct UpgradeRecommendation: Identifiable {
    let id = UUID()
    let type: UpgradeType
    let title: String
    let description: String
    let currentTier: PricingTier
    let suggestedTier: PricingTier
    let urgency: UpgradeUrgency
    let estimatedSavings: Int // In cents
    let benefits: [String]
    
    var costDifference: Int {
        suggestedTier.totalPrice - currentTier.totalPrice
    }
    
    var isUpgrade: Bool {
        costDifference > 0
    }
}

enum UpgradeType: String, CaseIterable {
    case patientCapacity = "Capacidade de Pacientes"
    case featureUpgrade = "Recursos Avançados"
    case performance = "Performance"
    case automatic = "Automático"
}

enum UpgradeUrgency: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        case .critical: return "Crítica"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct UpgradeAnalytics {
    let totalRecommendations: Int
    let highPriorityRecommendations: Int
    let potentialMonthlySavings: Int
    let currentUtilization: Double
    let recommendedActions: [UpgradeType]
}

struct UpgradeReport {
    let generatedAt: Date
    let psychologistId: String
    let currentUsage: UsageMetrics
    let recommendations: [UpgradeRecommendation]
    let projectedGrowth: ProjectedGrowth?
    let estimatedROI: Double
}

struct ProjectedGrowth {
    let timeframe: GrowthTimeframe
    let projectedPatients: Int
    let confidenceLevel: Double
    let factors: [String]
    
    enum GrowthTimeframe {
        case oneMonth
        case threeMonths
        case sixMonths
        case oneYear
        
        var displayName: String {
            switch self {
            case .oneMonth: return "1 mês"
            case .threeMonths: return "3 meses"
            case .sixMonths: return "6 meses"
            case .oneYear: return "1 ano"
            }
        }
    }
}
