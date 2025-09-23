import ManusPsiqueiaCore
//
//  PatientManagementDashboard.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Charts

public struct PatientManagementDashboard: View {
    @StateObject private var upgradeManager = AutoUpgradeManager.shared
    @StateObject private var calculator = DynamicPricingCalculator()
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showingUpgradeSheet = false
    @State private var showingAddPatientSheet = false
    @State private var animateMetrics = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with current plan info
                headerSection
                
                // Usage Overview
                usageOverviewSection
                
                // Patient Capacity Gauge
                capacityGaugeSection
                
                // Upgrade Recommendations
                if !upgradeManager.upgradeRecommendations.isEmpty {
                    upgradeRecommendationsSection
                }
                
                // Patient Analytics
                patientAnalyticsSection
                
                // Financial Impact
                financialImpactSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Gestão de Pacientes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPatientSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            if let recommendation = upgradeManager.pendingUpgrade {
                UpgradeRecommendationSheet(recommendation: recommendation)
            }
        }
        .sheet(isPresented: $showingAddPatientSheet) {
            AddPatientSheet()
        }
        .alert("Upgrade Recomendado", isPresented: $upgradeManager.showingUpgradeAlert) {
            Button("Ver Detalhes") {
                showingUpgradeSheet = true
            }
            Button("Mais Tarde", role: .cancel) {
                upgradeManager.dismissUpgradeRecommendation()
            }
        } message: {
            if let recommendation = upgradeManager.pendingUpgrade {
                Text(recommendation.description)
            }
        }
        .onAppear {
            animateMetrics = true
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plano Atual")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let tier = calculator.recommendedTier {
                        Text(tier.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Custo Mensal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(calculator.formatCurrency(calculator.calculatedPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
            // Time frame selector
            Picker("Período", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var usageOverviewSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Visão Geral do Uso")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let usage = upgradeManager.currentUsage {
                    Text("Atualizado há \(timeAgo(usage.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                UsageMetricCard(
                    title: "Pacientes Ativos",
                    value: "\(upgradeManager.currentUsage?.currentPatients ?? 0)",
                    subtitle: "de \(upgradeManager.currentUsage?.maxPatients ?? 0) disponíveis",
                    icon: "person.2.fill",
                    color: .blue,
                    animate: animateMetrics
                )
                
                UsageMetricCard(
                    title: "Sessões este Mês",
                    value: "\(upgradeManager.currentUsage?.monthlyUsage["sessions"] ?? 0)",
                    subtitle: "média de 4 por paciente",
                    icon: "calendar",
                    color: .green,
                    animate: animateMetrics
                )
                
                UsageMetricCard(
                    title: "Relatórios Gerados",
                    value: "\(upgradeManager.currentUsage?.monthlyUsage["reports_generated"] ?? 0)",
                    subtitle: "este período",
                    icon: "doc.text.fill",
                    color: .orange,
                    animate: animateMetrics
                )
                
                UsageMetricCard(
                    title: "Insights de IA",
                    value: "\(upgradeManager.currentUsage?.monthlyUsage["ai_insights"] ?? 0)",
                    subtitle: "análises realizadas",
                    icon: "brain.head.profile",
                    color: .purple,
                    animate: animateMetrics
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var capacityGaugeSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Capacidade de Pacientes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let usage = upgradeManager.currentUsage {
                    Text("\(Int(usage.utilizationPercentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getCapacityColor(usage.utilizationPercentage))
                }
            }
            
            if let usage = upgradeManager.currentUsage {
                VStack(spacing: 16) {
                    // Capacity Gauge
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: usage.utilizationPercentage / 100)
                            .stroke(
                                getCapacityColor(usage.utilizationPercentage),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: animateMetrics)
                        
                        VStack(spacing: 4) {
                            Text("\(usage.currentPatients)")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("de \(usage.maxPatients)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Capacity Status
                    HStack {
                        Image(systemName: getCapacityIcon(usage.utilizationPercentage))
                            .foregroundColor(getCapacityColor(usage.utilizationPercentage))
                        
                        Text(getCapacityMessage(usage.utilizationPercentage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(getCapacityColor(usage.utilizationPercentage))
                    }
                    
                    // Projected Timeline
                    if usage.utilizationPercentage > 70 {
                        VStack(spacing: 8) {
                            Text("Projeção de Capacidade")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text("Capacidade máxima em:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(getProjectedTimeToCapacity(usage))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var upgradeRecommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recomendações de Upgrade")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(upgradeManager.upgradeRecommendations.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(upgradeManager.upgradeRecommendations.prefix(3)) { recommendation in
                    UpgradeRecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            upgradeManager.pendingUpgrade = recommendation
                            showingUpgradeSheet = true
                        }
                    )
                }
            }
            
            if upgradeManager.upgradeRecommendations.count > 3 {
                Button("Ver Todas as Recomendações") {
                    // Navigate to full recommendations view
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var patientAnalyticsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Analytics de Pacientes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Patient Growth Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Crescimento de Pacientes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Chart(getPatientGrowthData()) { dataPoint in
                    LineMark(
                        x: .value("Mês", dataPoint.month),
                        y: .value("Pacientes", dataPoint.patients)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Mês", dataPoint.month),
                        y: .value("Pacientes", dataPoint.patients)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
            
            // Key Metrics
            HStack(spacing: 16) {
                AnalyticsMetric(
                    title: "Taxa de Crescimento",
                    value: "+15%",
                    subtitle: "últimos 3 meses",
                    color: .green
                )
                
                AnalyticsMetric(
                    title: "Retenção",
                    value: "92%",
                    subtitle: "pacientes ativos",
                    color: .blue
                )
                
                AnalyticsMetric(
                    title: "Satisfação",
                    value: "4.8",
                    subtitle: "avaliação média",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var financialImpactSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Impacto Financeiro")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            let roi = calculator.getEstimatedROI()
            
            HStack(spacing: 16) {
                FinancialMetricCard(
                    title: "Receita Mensal",
                    value: calculator.formatCurrency(roi.monthlyRevenue),
                    change: "+12%",
                    isPositive: true
                )
                
                FinancialMetricCard(
                    title: "Lucro Líquido",
                    value: calculator.formatCurrency(roi.monthlyProfit),
                    change: "+8%",
                    isPositive: true
                )
            }
            
            HStack(spacing: 16) {
                FinancialMetricCard(
                    title: "ROI",
                    value: "\(Int(roi.roi))%",
                    change: "+5%",
                    isPositive: true
                )
                
                FinancialMetricCard(
                    title: "Custo por Paciente",
                    value: calculator.formatCurrency(calculator.calculatedPrice / max(1, calculator.selectedPatientCount)),
                    change: "-3%",
                    isPositive: true
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingAddPatientSheet = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Adicionar Paciente")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack(spacing: 12) {
                Button("Personalizar Plano") {
                    // Navigate to plan calculator
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple, lineWidth: 1)
                )
                .foregroundColor(.purple)
                
                Button("Ver Relatório") {
                    // Generate and show usage report
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getCapacityColor(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<70: return .green
        case 70..<85: return .orange
        case 85..<95: return .red
        default: return .purple
        }
    }
    
    private func getCapacityIcon(_ percentage: Double) -> String {
        switch percentage {
        case 0..<70: return "checkmark.circle.fill"
        case 70..<85: return "exclamationmark.triangle.fill"
        case 85..<95: return "exclamationmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private func getCapacityMessage(_ percentage: Double) -> String {
        switch percentage {
        case 0..<70: return "Capacidade saudável"
        case 70..<85: return "Aproximando do limite"
        case 85..<95: return "Upgrade recomendado"
        default: return "Upgrade urgente"
        }
    }
    
    private func getProjectedTimeToCapacity(_ usage: UsageMetrics) -> String {
        let remainingCapacity = usage.maxPatients - usage.currentPatients
        let growthRate = 2 // 2 pacientes por mês (estimativa)
        let monthsToCapacity = max(1, remainingCapacity / growthRate)
        
        if monthsToCapacity == 1 {
            return "1 mês"
        } else {
            return "\(monthsToCapacity) meses"
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func getPatientGrowthData() -> [PatientGrowthDataPoint] {
        // Mock data - in real app, this would come from your backend
        return [
            PatientGrowthDataPoint(month: "Jan", patients: 15),
            PatientGrowthDataPoint(month: "Fev", patients: 18),
            PatientGrowthDataPoint(month: "Mar", patients: 22),
            PatientGrowthDataPoint(month: "Abr", patients: 25),
            PatientGrowthDataPoint(month: "Mai", patients: 28),
            PatientGrowthDataPoint(month: "Jun", patients: 28)
        ]
    }
}

// MARK: - Supporting Views
public struct UsageMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animate)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

public struct UpgradeRecommendationCard: View {
    let recommendation: UpgradeRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack {
                    Circle()
                        .fill(recommendation.urgency.color)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Text(recommendation.urgency.displayName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(recommendation.urgency.color)
                            .clipShape(Capsule())
                    }
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if recommendation.estimatedSavings > 0 {
                        Text("Economia: \(DynamicPricingCalculator().formatCurrency(recommendation.estimatedSavings))")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct AnalyticsMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

public struct FinancialMetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(isPositive ? .green : .red)
                    .font(.caption)
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Supporting Models
public enum TimeFrame: String, CaseIterable {
    case week = "Semana"
    case month = "Mês"
    case quarter = "Trimestre"
    case year = "Ano"
    
    var displayName: String {
        return self.rawValue
    }
}

public struct PatientGrowthDataPoint {
    let month: String
    let patients: Int
}

// MARK: - Sheet Views
public struct UpgradeRecommendationSheet: View {
    let recommendation: UpgradeRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(recommendation.urgency.color)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                        
                        VStack(spacing: 8) {
                            Text(recommendation.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(recommendation.urgency.displayName)
                                .font(.subheadline)
                                .foregroundColor(recommendation.urgency.color)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Description
                    Text(recommendation.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Plan Comparison
                    VStack(spacing: 16) {
                        Text("Comparação de Planos")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            PlanComparisonCard(
                                title: "Plano Atual",
                                planName: recommendation.currentTier.name,
                                price: recommendation.currentTier.totalPrice,
                                isCurrent: true
                            )
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                            
                            PlanComparisonCard(
                                title: "Plano Sugerido",
                                planName: recommendation.suggestedTier.name,
                                price: recommendation.suggestedTier.totalPrice,
                                isCurrent: false
                            )
                        }
                    }
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefícios do Upgrade")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(recommendation.benefits, id: \.self) { benefit in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text(benefit)
                                    .font(.subheadline)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await AutoUpgradeManager.shared.acceptUpgradeRecommendation(recommendation)
                            }
                            dismiss()
                        }) {
                            Text("Fazer Upgrade Agora")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(recommendation.urgency.color)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button("Mais Tarde") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Recomendação de Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

public struct PlanComparisonCard: View {
    let title: String
    let planName: String
    let price: Int
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(planName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(DynamicPricingCalculator().formatCurrency(price))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isCurrent ? .secondary : .green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color(.systemGray6) : Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color.clear : Color.green, lineWidth: 1)
                )
        )
    }
}

public struct AddPatientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patientName = ""
    @State private var patientEmail = ""
    @State private var patientPhone = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Adicionar Novo Paciente")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField("Nome completo", text: $patientName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $patientEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    
                    TextField("Telefone", text: $patientPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                Button("Adicionar Paciente") {
                    // Add patient logic
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.purple)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(patientName.isEmpty || patientEmail.isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
public struct PatientManagementDashboard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientManagementDashboard()
        }
    }
}
