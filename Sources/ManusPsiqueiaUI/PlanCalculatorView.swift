import ManusPsiqueiaCore
//
//  PlanCalculatorView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct PlanCalculatorView: View {
    @StateObject private var calculator = DynamicPricingCalculator()
    @State private var showingFeatureDetails = false
    @State private var selectedFeatureForDetails: PlanFeature?
    @State private var showingROIDetails = false
    @State private var animatePrice = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Patient Count Selector
                patientCountSection
                
                // Recommended Tier
                recommendedTierSection
                
                // Features Selection
                featuresSection
                
                // Billing Cycle
                billingCycleSection
                
                // Price Summary
                priceSummarySection
                
                // ROI Calculator
                roiSection
                
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
        .navigationTitle("Monte seu Plano")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingFeatureDetails) {
            if let feature = selectedFeatureForDetails {
                FeatureDetailView(feature: feature)
            }
        }
        .sheet(isPresented: $showingROIDetails) {
            ROIDetailView(calculator: calculator)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Calculadora de Planos")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Personalize seu plano baseado no número de pacientes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var patientCountSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Quantos pacientes você atende?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(calculator.selectedPatientCount)")
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
            
            // Custom Slider
            VStack(spacing: 12) {
                Slider(
                    value: Binding(
                        get: { Double(calculator.selectedPatientCount) },
                        set: { calculator.updatePatientCount(Int($0)) }
                    ),
                    in: 1...200,
                    step: 1
                )
                .accentColor(.purple)
                
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("200+")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Select Buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach([5, 15, 30, 50], id: \.self) { count in
                    Button(action: {
                        calculator.updatePatientCount(count)
                    }) {
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(height: 36)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(calculator.selectedPatientCount == count ? Color.purple : Color(.systemGray5))
                            )
                            .foregroundColor(calculator.selectedPatientCount == count ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
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
    
    private var recommendedTierSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Plano Recomendado")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let tier = calculator.recommendedTier, tier.isPopular {
                    Text("MAIS POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            if let tier = calculator.recommendedTier {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(tier.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(calculator.formatCurrency(tier.calculatePrice(for: calculator.selectedPatientCount)))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("por mês")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(tier.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if tier.discount > 0 {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text("\(Int(tier.discount * 100))% de desconto incluído")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(tier.features.prefix(4), id: \.self) { feature in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(feature)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
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
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recursos Adicionais")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(calculator.selectedFeatures.count) selecionados")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(calculator.availableFeatures.filter { !$0.isEssential }) { feature in
                    FeatureCard(
                        feature: feature,
                        isSelected: calculator.selectedFeatures.contains(feature),
                        patientCount: calculator.selectedPatientCount,
                        onToggle: {
                            calculator.toggleFeature(feature)
                        },
                        onShowDetails: {
                            selectedFeatureForDetails = feature
                            showingFeatureDetails = true
                        }
                    )
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
    
    private var billingCycleSection: some View {
        VStack(spacing: 16) {
            Text("Ciclo de Cobrança")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ForEach(DynamicPricingCalculator.BillingCycle.allCases, id: \.self) { cycle in
                    Button(action: {
                        calculator.setBillingCycle(cycle)
                    }) {
                        VStack(spacing: 8) {
                            Text(cycle.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            if cycle.discount > 0 {
                                Text("Economize \(Int(cycle.discount * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            } else {
                                Text("Flexibilidade total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(calculator.billingCycle == cycle ? Color.purple.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            calculator.billingCycle == cycle ? Color.purple : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
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
    
    private var priceSummarySection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Resumo do Plano")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Base price breakdown
                if let tier = calculator.recommendedTier {
                    PriceBreakdownRow(
                        title: "Plano \(tier.name)",
                        subtitle: "\(calculator.selectedPatientCount) pacientes",
                        price: tier.calculatePrice(for: calculator.selectedPatientCount)
                    )
                }
                
                // Features breakdown
                ForEach(Array(calculator.selectedFeatures), id: \.id) { feature in
                    PriceBreakdownRow(
                        title: feature.name,
                        subtitle: "Recurso adicional",
                        price: feature.basePrice + (feature.pricePerPatient * calculator.selectedPatientCount)
                    )
                }
                
                Divider()
                
                // Total
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total \(calculator.billingCycle.rawValue)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if calculator.billingCycle.discount > 0 {
                            Text("Economia de \(Int(calculator.billingCycle.discount * 100))% aplicada")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Text(calculator.formatCurrency(calculator.calculatedPrice))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(animatePrice ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: animatePrice)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .onChange(of: calculator.calculatedPrice) { _ in
            animatePrice = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePrice = false
            }
        }
    }
    
    private var roiSection: some View {
        let roi = calculator.getEstimatedROI()
        
        return VStack(spacing: 16) {
            HStack {
                Text("Análise de ROI")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Ver Detalhes") {
                    showingROIDetails = true
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            HStack(spacing: 20) {
                ROIMetricCard(
                    title: "ROI Mensal",
                    value: "\(Int(roi.roi))%",
                    subtitle: "Retorno sobre investimento",
                    color: roi.roi > 0 ? .green : .red
                )
                
                ROIMetricCard(
                    title: "Break-even",
                    value: "\(roi.breakEvenPatients)",
                    subtitle: "pacientes necessários",
                    color: .blue
                )
            }
            
            if roi.roi > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Plano viável! Lucro estimado de \(calculator.formatCurrency(roi.monthlyProfit))/mês")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
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
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                // Implement plan selection
            }) {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("Assinar este Plano")
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
            
            Button(action: {
                // Implement save for later
            }) {
                Text("Salvar Configuração")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                    .foregroundColor(.purple)
            }
        }
    }
}

public struct FeatureCard: View {
    let feature: PlanFeature
    let isSelected: Bool
    let patientCount: Int
    let onToggle: () -> Void
    let onShowDetails: () -> Void
    
    private var totalPrice: Int {
        feature.basePrice + (feature.pricePerPatient * patientCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .green : .secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            HStack {
                Text(DynamicPricingCalculator().formatCurrency(totalPrice))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Button("Detalhes") {
                    onShowDetails()
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.purple.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.purple : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            onToggle()
        }
    }
}

public struct PriceBreakdownRow: View {
    let title: String
    let subtitle: String
    let price: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DynamicPricingCalculator().formatCurrency(price))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

public struct ROIMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview
public struct PlanCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlanCalculatorView()
        }
    }
}
