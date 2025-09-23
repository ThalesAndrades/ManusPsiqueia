//
//  PsychologistFinancialDashboard.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Charts

struct PsychologistFinancialDashboard: View {
    @StateObject private var paymentService = SessionPaymentService.shared
    @StateObject private var connectManager = StripeConnectManager.shared
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var analytics: ConnectAnalytics?
    @State private var showingPaymentHistory = false
    @State private var showingDashboardLink = false
    @State private var isLoading = true
    
    let psychologist: User
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingView
                    } else {
                        headerSection
                        analyticsSection
                        quickActionsSection
                        recentTransactionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard Financeiro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Histórico Completo") {
                            showingPaymentHistory = true
                        }
                        
                        Button("Dashboard Stripe") {
                            openStripeDashboard()
                        }
                        
                        Button("Atualizar Dados") {
                            loadAnalytics()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaymentHistory) {
            PaymentHistoryView(psychologist: psychologist)
        }
        .onAppear {
            loadAnalytics()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando dados financeiros...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Olá, \(psychologist.fullName.components(separatedBy: " ").first ?? "")")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Aqui está um resumo dos seus ganhos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            // Seletor de período
            Picker("Período", selection: $selectedPeriod) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedPeriod) { _ in
                loadAnalytics()
            }
        }
    }
    
    private var analyticsSection: some View {
        VStack(spacing: 16) {
            if let analytics = analytics {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    AnalyticsCard(
                        title: "Receita Total",
                        value: analytics.formattedTotalRevenue,
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    AnalyticsCard(
                        title: "Valor Líquido",
                        value: analytics.formattedTotalPayouts,
                        icon: "banknote.fill",
                        color: .blue
                    )
                    
                    AnalyticsCard(
                        title: "Transações",
                        value: "\(analytics.transactionCount)",
                        icon: "creditcard.fill",
                        color: .orange
                    )
                    
                    AnalyticsCard(
                        title: "Ticket Médio",
                        value: analytics.formattedAverageTransaction,
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                }
                
                // Gráfico de receita (placeholder - implementar com dados reais)
                revenueChart
            } else {
                Text("Nenhum dado disponível")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }
    
    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receita nos Últimos 7 Dias")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder para gráfico - implementar com dados reais
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Gráfico de receita")
                            .foregroundColor(.secondary)
                    }
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ações Rápidas")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Ver Histórico",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                ) {
                    showingPaymentHistory = true
                }
                
                QuickActionButton(
                    title: "Dashboard Stripe",
                    icon: "link.circle",
                    color: .purple
                ) {
                    openStripeDashboard()
                }
                
                QuickActionButton(
                    title: "Configurações",
                    icon: "gear.circle",
                    color: .gray
                ) {
                    // Implementar navegação para configurações
                }
                
                QuickActionButton(
                    title: "Suporte",
                    icon: "questionmark.circle",
                    color: .orange
                ) {
                    // Implementar navegação para suporte
                }
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Transações Recentes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Ver Todas") {
                    showingPaymentHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            let recentPayments = paymentService.getPaymentHistory(
                for: psychologist.id.uuidString,
                userType: .psychologist
            ).prefix(5)
            
            if recentPayments.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "Nenhuma transação",
                    description: "Suas transações aparecerão aqui"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(recentPayments), id: \.id) { payment in
                        TransactionRow(payment: payment)
                    }
                }
            }
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        
        Task {
            do {
                let analyticsData = try await paymentService.getPaymentAnalytics(
                    for: psychologist.id.uuidString,
                    period: selectedPeriod
                )
                
                await MainActor.run {
                    self.analytics = analyticsData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Mostrar erro
                }
            }
        }
    }
    
    private func openStripeDashboard() {
        Task {
            do {
                // Buscar account ID do psicólogo
                guard let accountId = KeychainWrapper.standard.string(forKey: "stripe_connect_\(psychologist.id)") else {
                    return
                }
                
                let dashboardURL = try await connectManager.createDashboardLink(accountId: accountId)
                
                if let url = URL(string: dashboardURL) {
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }
            } catch {
                // Mostrar erro
            }
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransactionRow: View {
    let payment: SessionPayment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sessão de Terapia")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(payment.scheduledDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: payment.status.icon)
                        .font(.caption)
                    
                    Text(payment.status.displayName)
                        .font(.caption)
                }
                .foregroundColor(payment.status.color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

// MARK: - Preview

struct PsychologistFinancialDashboard_Previews: PreviewProvider {
    static var previews: some View {
        PsychologistFinancialDashboard(
            psychologist: User(
                id: UUID(),
                email: "psicologo@exemplo.com",
                fullName: "Dr. João Silva",
                userType: .psychologist,
                isActive: true,
                createdAt: Date(),
                lastLoginAt: Date()
            )
        )
    }
}
