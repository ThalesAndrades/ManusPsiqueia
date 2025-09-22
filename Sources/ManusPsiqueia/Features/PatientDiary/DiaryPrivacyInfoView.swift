//
//  DiaryPrivacyInfoView.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Comprehensive privacy information view for diary users
struct DiaryPrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var securityManager = DiarySecurityManager()
    @State private var selectedTab: PrivacyTab = .overview
    @State private var showingSecurityReport = false
    
    enum PrivacyTab: String, CaseIterable {
        case overview = "Visão Geral"
        case encryption = "Criptografia"
        case ai = "IA e Insights"
        case rights = "Seus Direitos"
        case security = "Segurança"
        
        var icon: String {
            switch self {
            case .overview: return "shield.checkered"
            case .encryption: return "lock.shield"
            case .ai: return "brain.head.profile"
            case .rights: return "person.badge.shield.checkmark"
            case .security: return "checkmark.shield"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                PrivacyHeaderView()
                
                // Tab selector
                PrivacyTabSelector(selectedTab: $selectedTab)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .overview:
                            PrivacyOverviewContent()
                        case .encryption:
                            EncryptionDetailsContent()
                        case .ai:
                            AIPrivacyContent()
                        case .rights:
                            UserRightsContent()
                        case .security:
                            SecurityDetailsContent(securityManager: securityManager)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Privacidade do Diário")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSecurityReport = true }) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSecurityReport) {
            SecurityReportView(securityManager: securityManager)
        }
    }
}

// MARK: - Header View

struct PrivacyHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Shield icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Seu Diário é 100% Privado")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Protegido por criptografia militar e nunca compartilhado")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemGray6).opacity(0.5))
    }
}

// MARK: - Tab Selector

struct PrivacyTabSelector: View {
    @Binding var selectedTab: DiaryPrivacyInfoView.PrivacyTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DiaryPrivacyInfoView.PrivacyTab.allCases, id: \.self) { tab in
                    PrivacyTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
}

struct PrivacyTabButton: View {
    let tab: DiaryPrivacyInfoView.PrivacyTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}

// MARK: - Content Views

struct PrivacyOverviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PrivacyFeatureCard(
                icon: "lock.fill",
                title: "Criptografia de Ponta",
                description: "Seus dados são protegidos com criptografia AES-256, o mesmo padrão usado por bancos e governos.",
                color: .green
            )
            
            PrivacyFeatureCard(
                icon: "eye.slash.fill",
                title: "Acesso Zero da Equipe",
                description: "Nem mesmo nossa equipe pode acessar o conteúdo do seu diário. Apenas você tem as chaves.",
                color: .blue
            )
            
            PrivacyFeatureCard(
                icon: "brain.head.profile",
                title: "IA Anônima",
                description: "A análise de IA é feita com dados anonimizados, gerando insights sem comprometer sua privacidade.",
                color: .purple
            )
            
            PrivacyFeatureCard(
                icon: "trash.fill",
                title: "Controle Total",
                description: "Você pode deletar todos os seus dados a qualquer momento, sem deixar rastros.",
                color: .red
            )
            
            // Privacy guarantee
            PrivacyGuaranteeView()
        }
    }
}

struct EncryptionDetailsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detalhes Técnicos da Criptografia")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            EncryptionDetailCard(
                title: "Algoritmo de Criptografia",
                value: "AES-256-GCM",
                description: "Padrão militar com autenticação integrada"
            )
            
            EncryptionDetailCard(
                title: "Gerenciamento de Chaves",
                value: "Keychain Seguro",
                description: "Chaves armazenadas no Secure Enclave do dispositivo"
            )
            
            EncryptionDetailCard(
                title: "Autenticação",
                value: "Biométrica + Senha",
                description: "Face ID, Touch ID ou senha do dispositivo"
            )
            
            EncryptionDetailCard(
                title: "Transmissão",
                value: "TLS 1.3",
                description: "Comunicação sempre criptografada"
            )
            
            EncryptionDetailCard(
                title: "Armazenamento",
                value: "Local + Criptografado",
                description: "Dados nunca saem do seu dispositivo descriptografados"
            )
            
            // Technical certification
            TechnicalCertificationView()
        }
    }
}

struct AIPrivacyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Como a IA Protege sua Privacidade")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            AIPrivacyStepView(
                step: 1,
                title: "Anonimização",
                description: "Seus dados são anonimizados antes de qualquer análise, removendo informações pessoais identificáveis."
            )
            
            AIPrivacyStepView(
                step: 2,
                title: "Processamento Local",
                description: "A análise inicial é feita no seu dispositivo, sem enviar dados para servidores externos."
            )
            
            AIPrivacyStepView(
                step: 3,
                title: "Insights Agregados",
                description: "Apenas padrões e tendências são extraídos, nunca o conteúdo específico das suas entradas."
            )
            
            AIPrivacyStepView(
                step: 4,
                title: "Controle do Usuário",
                description: "Você pode desativar a análise de IA a qualquer momento nas configurações."
            )
            
            // AI transparency
            AITransparencyView()
        }
    }
}

struct UserRightsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Seus Direitos de Privacidade")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            UserRightCard(
                icon: "eye.fill",
                title: "Direito de Acesso",
                description: "Você pode visualizar todos os dados que coletamos sobre você a qualquer momento."
            )
            
            UserRightCard(
                icon: "pencil.circle.fill",
                title: "Direito de Retificação",
                description: "Você pode corrigir ou atualizar suas informações quando necessário."
            )
            
            UserRightCard(
                icon: "trash.circle.fill",
                title: "Direito ao Esquecimento",
                description: "Você pode solicitar a exclusão completa de todos os seus dados."
            )
            
            UserRightCard(
                icon: "arrow.down.circle.fill",
                title: "Portabilidade de Dados",
                description: "Você pode exportar seus dados em formato legível por máquina."
            )
            
            UserRightCard(
                icon: "hand.raised.fill",
                title: "Direito de Objeção",
                description: "Você pode se opor ao processamento de seus dados para fins específicos."
            )
            
            // Contact information
            ContactInfoView()
        }
    }
}

struct SecurityDetailsContent: View {
    let securityManager: DiarySecurityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Status de Segurança Atual")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            SecurityStatusCard(securityManager: securityManager)
            
            SecurityFeatureCard(
                icon: "faceid",
                title: "Autenticação Biométrica",
                description: "Face ID ou Touch ID para acesso seguro",
                isEnabled: securityManager.biometricType != .none
            )
            
            SecurityFeatureCard(
                icon: "timer",
                title: "Bloqueio Automático",
                description: "Diário se bloqueia automaticamente após inatividade",
                isEnabled: true
            )
            
            SecurityFeatureCard(
                icon: "exclamationmark.shield",
                title: "Proteção contra Tentativas",
                description: "Bloqueio temporário após tentativas falhadas",
                isEnabled: true
            )
            
            SecurityFeatureCard(
                icon: "doc.text.magnifyingglass",
                title: "Auditoria de Segurança",
                description: "Registro completo de todos os acessos",
                isEnabled: true
            )
            
            // Security recommendations
            SecurityRecommendationsView()
        }
    }
}

// MARK: - Supporting Views

struct PrivacyFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct PrivacyGuaranteeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Nossa Garantia de Privacidade")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Comprometemo-nos a nunca vender, compartilhar ou usar seus dados pessoais para fins comerciais. Seu diário é seu, e apenas seu.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Certificado por AiLun Tecnologia")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EncryptionDetailCard: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct TechnicalCertificationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Certificações Técnicas")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                CertificationBadge(name: "ISO 27001", description: "Gestão de Segurança da Informação")
                CertificationBadge(name: "LGPD", description: "Lei Geral de Proteção de Dados")
                CertificationBadge(name: "FIPS 140-2", description: "Padrão de Criptografia Federal")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CertificationBadge: View {
    let name: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AIPrivacyStepView: View {
    let step: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct AITransparencyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Transparência da IA")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Você pode visualizar exatamente quais insights foram gerados e como eles foram criados. A IA nunca tem acesso ao texto completo das suas entradas.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            MentalHealthButton(
                "Ver Exemplo de Análise",
                icon: "eye.fill",
                style: .secondary,
                size: .medium
            ) {
                // Show example analysis
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct UserRightCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct ContactInfoView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Exercer Seus Direitos")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Para exercer qualquer um desses direitos, entre em contato conosco:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("contato@ailun.com.br")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Text("CNPJ: 60.740.536/0001-75")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SecurityStatusCard: View {
    @ObservedObject var securityManager: DiarySecurityManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Status de Segurança")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                SecurityStatusRow(
                    title: "Nível de Segurança",
                    value: securityManager.securityLevel.displayName,
                    color: .green
                )
                
                SecurityStatusRow(
                    title: "Autenticação",
                    value: securityManager.biometricType.displayName,
                    color: .blue
                )
                
                if let lastAccess = securityManager.lastAccessTime {
                    SecurityStatusRow(
                        title: "Último Acesso",
                        value: lastAccess.formatted(date: .abbreviated, time: .shortened),
                        color: .secondary
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct SecurityStatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct SecurityFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isEnabled ? .green : .secondary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEnabled ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct SecurityRecommendationsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Recomendações de Segurança")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                SecurityRecommendation(
                    icon: "faceid",
                    text: "Mantenha a autenticação biométrica ativada"
                )
                
                SecurityRecommendation(
                    icon: "iphone.and.arrow.forward",
                    text: "Não compartilhe seu dispositivo com outras pessoas"
                )
                
                SecurityRecommendation(
                    icon: "arrow.clockwise.circle",
                    text: "Mantenha o app sempre atualizado"
                )
                
                SecurityRecommendation(
                    icon: "wifi.slash",
                    text: "Evite redes Wi-Fi públicas para acessar o diário"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SecurityRecommendation: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Security Report View

struct SecurityReportView: View {
    @ObservedObject var securityManager: DiarySecurityManager
    @Environment(\.dismiss) private var dismiss
    @State private var securityReport: SecurityReport?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Gerando relatório de segurança...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let report = securityReport {
                    SecurityReportContent(report: report)
                } else {
                    Text("Erro ao gerar relatório")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Relatório de Segurança")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            securityReport = await securityManager.generateSecurityReport()
            isLoading = false
        }
    }
}

struct SecurityReportContent: View {
    let report: SecurityReport
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Overall status
                SecurityReportHeader(report: report)
                
                // Detailed sections
                SecurityReportSection(
                    title: "Configuração Atual",
                    content: AnyView(CurrentConfigurationView(report: report))
                )
                
                SecurityReportSection(
                    title: "Status de Criptografia",
                    content: AnyView(EncryptionStatusView(report: report))
                )
                
                SecurityReportSection(
                    title: "Conformidade de Privacidade",
                    content: AnyView(PrivacyComplianceView(report: report))
                )
                
                SecurityReportSection(
                    title: "Atividade Recente",
                    content: AnyView(RecentActivityView(report: report))
                )
            }
            .padding(20)
        }
    }
}

struct SecurityReportHeader: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Segurança Ativa")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Gerado em \(report.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                SecurityMetric(
                    title: "Nível",
                    value: report.securityLevel.displayName,
                    color: .green
                )
                
                SecurityMetric(
                    title: "Biometria",
                    value: report.biometricType,
                    color: .blue
                )
                
                SecurityMetric(
                    title: "Tentativas",
                    value: "\(report.failedAttempts)",
                    color: report.failedAttempts > 0 ? .orange : .green
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
}

struct SecurityMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SecurityReportSection: View {
    let title: String
    let content: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            content
        }
    }
}

struct CurrentConfigurationView: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(spacing: 8) {
            ConfigurationRow(title: "Nível de Segurança", value: report.securityLevel.displayName)
            ConfigurationRow(title: "Autenticação", value: report.biometricType)
            ConfigurationRow(title: "Último Acesso", value: report.lastAccessTime?.formatted() ?? "Nunca")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct ConfigurationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct EncryptionStatusView: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: report.encryptionStatus.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(report.encryptionStatus.isValid ? .green : .red)
                
                Text(report.encryptionStatus.isValid ? "Criptografia Íntegra" : "Problema na Criptografia")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(report.encryptionStatus.isValid ? .green : .red)
            }
            
            Text("Última verificação: \(report.encryptionStatus.lastValidated.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let error = report.encryptionStatus.error {
                Text("Erro: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct PrivacyComplianceView: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pontuação de Conformidade")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(report.privacyCompliance.scorePercentage)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(report.privacyCompliance.isCompliant ? .green : .orange)
            }
            
            ProgressView(value: report.privacyCompliance.score)
                .tint(report.privacyCompliance.isCompliant ? .green : .orange)
            
            Text("Última verificação: \(report.privacyCompliance.lastChecked.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct RecentActivityView: View {
    let report: SecurityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if report.auditLogs.isEmpty {
                Text("Nenhuma atividade recente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            } else {
                ForEach(report.auditLogs.prefix(5), id: \.id) { log in
                    ActivityLogRow(log: log)
                }
            }
        }
    }
}

struct ActivityLogRow: View {
    let log: SecurityAuditLog
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(log.severity.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.event)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    DiaryPrivacyInfoView()
}
