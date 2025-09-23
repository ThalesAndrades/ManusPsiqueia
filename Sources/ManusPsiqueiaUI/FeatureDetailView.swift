import ManusPsiqueiaCore
//
//  FeatureDetailView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct FeatureDetailView: View {
    let feature: PlanFeature
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
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
                            
                            Image(systemName: feature.icon)
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(feature.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(feature.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sobre este recurso")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(feature.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Pricing Details
                    pricingSection
                    
                    // Benefits
                    benefitsSection
                    
                    // Use Cases
                    useCasesSection
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Detalhes do Recurso")
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
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Precificação")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if feature.basePrice > 0 {
                    HStack {
                        Text("Taxa base")
                        Spacer()
                        Text(DynamicPricingCalculator().formatCurrency(feature.basePrice))
                            .fontWeight(.medium)
                    }
                }
                
                if feature.pricePerPatient > 0 {
                    HStack {
                        Text("Por paciente")
                        Spacer()
                        Text(DynamicPricingCalculator().formatCurrency(feature.pricePerPatient))
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                // Example calculation
                VStack(spacing: 8) {
                    Text("Exemplo para 20 pacientes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let examplePrice = feature.basePrice + (feature.pricePerPatient * 20)
                    HStack {
                        Text("Total mensal")
                        Spacer()
                        Text(DynamicPricingCalculator().formatCurrency(examplePrice))
                            .font(.title3)
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
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefícios")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(getBenefits(), id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text(benefit)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var useCasesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Casos de Uso")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                ForEach(getUseCases(), id: \.title) { useCase in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: useCase.icon)
                                .foregroundColor(.purple)
                                .font(.title3)
                            
                            Text(useCase.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text(useCase.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getBenefits() -> [String] {
        switch feature.name {
        case "Relatórios Avançados":
            return [
                "Visualização detalhada do progresso dos pacientes",
                "Gráficos interativos de evolução",
                "Exportação em PDF para compartilhamento",
                "Comparação entre períodos",
                "Métricas de engajamento"
            ]
        case "Dashboard Executivo":
            return [
                "Visão geral do negócio em tempo real",
                "KPIs financeiros automatizados",
                "Análise de tendências",
                "Alertas de performance",
                "Comparação com benchmarks"
            ]
        case "Insights de IA":
            return [
                "Análise automática dos diários",
                "Identificação de padrões emocionais",
                "Sugestões de intervenções",
                "Relatórios de progresso inteligentes",
                "Privacidade total garantida"
            ]
        case "Detecção de Risco":
            return [
                "Monitoramento contínuo de sinais de alerta",
                "Notificações em tempo real",
                "Escalas de risco personalizáveis",
                "Histórico de episódios críticos",
                "Protocolo de emergência integrado"
            ]
        case "Videochamadas HD":
            return [
                "Qualidade de vídeo superior",
                "Gravação de sessões (com consentimento)",
                "Compartilhamento de tela",
                "Sala de espera virtual",
                "Integração com agenda"
            ]
        case "Lembretes Inteligentes":
            return [
                "Notificações personalizadas",
                "Múltiplos canais (SMS, email, push)",
                "Lembretes de medicação",
                "Follow-up automático",
                "Configuração por paciente"
            ]
        case "API Personalizada":
            return [
                "Integração com sistemas existentes",
                "Webhook para eventos em tempo real",
                "Documentação completa",
                "Suporte técnico dedicado",
                "Rate limiting configurável"
            ]
        case "White Label":
            return [
                "Plataforma com sua marca",
                "Domínio personalizado",
                "Cores e logo customizáveis",
                "Remoção de branding ManusPsiqueia",
                "App mobile personalizado"
            ]
        case "Suporte Prioritário":
            return [
                "Atendimento 24/7",
                "Tempo de resposta garantido",
                "Canal direto com especialistas",
                "Treinamento personalizado",
                "Gerente de conta dedicado"
            ]
        default:
            return [
                "Recurso premium incluído",
                "Suporte técnico especializado",
                "Atualizações automáticas",
                "Documentação completa"
            ]
        }
    }
    
    private func getUseCases() -> [UseCase] {
        switch feature.name {
        case "Insights de IA":
            return [
                UseCase(
                    icon: "brain.head.profile",
                    title: "Análise de Humor",
                    description: "Identificar padrões de humor ao longo do tempo"
                ),
                UseCase(
                    icon: "exclamationmark.triangle.fill",
                    title: "Detecção Precoce",
                    description: "Identificar sinais de recaída ou piora"
                ),
                UseCase(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progresso Terapêutico",
                    description: "Medir eficácia das intervenções"
                )
            ]
        case "Detecção de Risco":
            return [
                UseCase(
                    icon: "heart.text.square",
                    title: "Ideação Suicida",
                    description: "Monitoramento de pensamentos de autolesão"
                ),
                UseCase(
                    icon: "exclamationmark.circle.fill",
                    title: "Crises de Ansiedade",
                    description: "Identificação de picos de ansiedade"
                ),
                UseCase(
                    icon: "phone.fill",
                    title: "Protocolo de Emergência",
                    description: "Acionamento automático de contatos"
                )
            ]
        case "White Label":
            return [
                UseCase(
                    icon: "building.2.fill",
                    title: "Clínicas Grandes",
                    description: "Plataforma com identidade própria"
                ),
                UseCase(
                    icon: "person.3.fill",
                    title: "Grupos de Psicólogos",
                    description: "Marca unificada para o grupo"
                ),
                UseCase(
                    icon: "globe",
                    title: "Expansão Internacional",
                    description: "Adaptação para diferentes mercados"
                )
            ]
        default:
            return [
                UseCase(
                    icon: "person.fill",
                    title: "Psicólogos Individuais",
                    description: "Melhoria da prática clínica"
                ),
                UseCase(
                    icon: "building.fill",
                    title: "Clínicas",
                    description: "Gestão eficiente de múltiplos profissionais"
                ),
                UseCase(
                    icon: "graduationcap.fill",
                    title: "Instituições de Ensino",
                    description: "Treinamento e supervisão"
                )
            ]
        }
    }
}

public struct UseCase {
    let icon: String
    let title: String
    let description: String
}

public struct ROIDetailView: View {
    @ObservedObject var calculator: DynamicPricingCalculator
    @Environment(\.dismiss) private var dismiss
    
    private var roi: ROICalculation {
        calculator.getEstimatedROI()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Análise de ROI")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Retorno sobre Investimento Detalhado")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // ROI Summary
                    VStack(spacing: 20) {
                        HStack {
                            Text("ROI Mensal")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(Int(roi.roi))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(roi.roi > 0 ? .green : .red)
                        }
                        
                        if roi.roi > 0 {
                            Text("Excelente! Seu plano é altamente lucrativo.")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("Considere ajustar o número de pacientes ou o valor das consultas.")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Financial Breakdown
                    financialBreakdownSection
                    
                    // Scenarios
                    scenariosSection
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Análise ROI")
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
    
    private var financialBreakdownSection: some View {
        VStack(spacing: 16) {
            Text("Detalhamento Financeiro")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                FinancialRow(
                    title: "Receita Mensal Estimada",
                    subtitle: "\(calculator.selectedPatientCount) pacientes × 4 sessões × R$ 150",
                    amount: roi.monthlyRevenue,
                    color: .green
                )
                
                FinancialRow(
                    title: "Custo da Plataforma",
                    subtitle: "Plano personalizado",
                    amount: roi.monthlyCost,
                    color: .red
                )
                
                Divider()
                
                FinancialRow(
                    title: "Lucro Líquido",
                    subtitle: "Receita - Custos",
                    amount: roi.monthlyProfit,
                    color: roi.monthlyProfit > 0 ? .green : .red,
                    isTotal: true
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var scenariosSection: some View {
        VStack(spacing: 16) {
            Text("Cenários Alternativos")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ScenarioCard(
                    title: "Cenário Conservador",
                    subtitle: "R$ 120 por sessão",
                    patients: calculator.selectedPatientCount,
                    sessionPrice: 12000,
                    planCost: calculator.calculatedPrice
                )
                
                ScenarioCard(
                    title: "Cenário Otimista",
                    subtitle: "R$ 180 por sessão",
                    patients: calculator.selectedPatientCount,
                    sessionPrice: 18000,
                    planCost: calculator.calculatedPrice
                )
                
                ScenarioCard(
                    title: "Crescimento 50%",
                    subtitle: "\(Int(Double(calculator.selectedPatientCount) * 1.5)) pacientes",
                    patients: Int(Double(calculator.selectedPatientCount) * 1.5),
                    sessionPrice: 15000,
                    planCost: calculator.calculatedPrice
                )
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendações")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(getRecommendations(), id: \.title) { recommendation in
                    HStack(spacing: 12) {
                        Image(systemName: recommendation.icon)
                            .foregroundColor(recommendation.color)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(recommendation.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(recommendation.color.opacity(0.1))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getRecommendations() -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        if roi.roi < 100 {
            recommendations.append(
                Recommendation(
                    icon: "arrow.up.circle.fill",
                    title: "Aumente o Valor das Consultas",
                    description: "Considere ajustar seus preços para R$ 170-200 por sessão",
                    color: .blue
                )
            )
        }
        
        if calculator.selectedPatientCount < roi.breakEvenPatients {
            recommendations.append(
                Recommendation(
                    icon: "person.2.fill",
                    title: "Aumente sua Base de Pacientes",
                    description: "Você precisa de pelo menos \(roi.breakEvenPatients) pacientes para o break-even",
                    color: .orange
                )
            )
        }
        
        if roi.roi > 300 {
            recommendations.append(
                Recommendation(
                    icon: "star.fill",
                    title: "Considere Recursos Premium",
                    description: "Seu ROI permite investir em recursos avançados como IA",
                    color: .green
                )
            )
        }
        
        recommendations.append(
            Recommendation(
                icon: "chart.line.uptrend.xyaxis",
                title: "Monitore Regularmente",
                description: "Revise seus números mensalmente para otimizar resultados",
                color: .purple
            )
        )
        
        return recommendations
    }
}

public struct FinancialRow: View {
    let title: String
    let subtitle: String
    let amount: Int
    let color: Color
    let isTotal: Bool
    
    init(title: String, subtitle: String, amount: Int, color: Color, isTotal: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.color = color
        self.isTotal = isTotal
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(isTotal ? .subheadline : .subheadline)
                    .fontWeight(isTotal ? .bold : .medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DynamicPricingCalculator().formatCurrency(amount))
                .font(isTotal ? .title3 : .subheadline)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(color)
        }
    }
}

public struct ScenarioCard: View {
    let title: String
    let subtitle: String
    let patients: Int
    let sessionPrice: Int
    let planCost: Int
    
    private var monthlyRevenue: Int {
        patients * 4 * sessionPrice
    }
    
    private var monthlyProfit: Int {
        monthlyRevenue - planCost
    }
    
    private var roi: Double {
        Double(monthlyProfit) / Double(planCost) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("ROI:")
                Spacer()
                Text("\(Int(roi))%")
                    .fontWeight(.bold)
                    .foregroundColor(roi > 0 ? .green : .red)
            }
            .font(.caption)
            
            HStack {
                Text("Lucro:")
                Spacer()
                Text(DynamicPricingCalculator().formatCurrency(monthlyProfit))
                    .fontWeight(.medium)
                    .foregroundColor(monthlyProfit > 0 ? .green : .red)
            }
            .font(.caption)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

public struct Recommendation {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview
public struct FeatureDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureDetailView(
            feature: PlanFeature(
                name: "Insights de IA",
                description: "Análise inteligente dos diários dos pacientes",
                icon: "brain.head.profile",
                pricePerPatient: 490,
                basePrice: 2990,
                category: .ai,
                isEssential: false
            )
        )
    }
}
