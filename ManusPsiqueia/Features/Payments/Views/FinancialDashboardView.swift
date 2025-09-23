//
//  FinancialDashboardView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Charts

struct FinancialDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var stripeManager: StripeManager
    @EnvironmentObject var invitationManager: InvitationManager
    
    @State private var selectedPeriod: FinancialPeriod = .month
    @State private var financialData: FinancialData?
    @State private var isLoading = false
    @State private var showingWithdrawSheet = false
    @State private var animateCards = false
    @State private var pulseAnimation = false
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated background
            FinancialBackgroundView(animateGradient: $pulseAnimation)
            
            // Floating particles
            FinancialParticlesView(offset: $particleOffset)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Quick stats
                    quickStatsSection
                    
                    // Revenue chart
                    revenueChartSection
                    
                    // Patient payments
                    patientPaymentsSection
                    
                    // Withdrawal section
                    withdrawalSection
                    
                    // Recent transactions
                    recentTransactionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            startAnimations()
            loadFinancialData()
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingWithdrawSheet) {
            WithdrawFundsView()
                .environmentObject(stripeManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and period selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard Financeiro")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Gestão completa das suas finanças")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Period selector
                Menu {
                    ForEach(FinancialPeriod.allCases, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                            loadFinancialData()
                        }) {
                            HStack {
                                Text(period.displayName)
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedPeriod.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Balance card
            balanceCard
        }
        .padding(.top, 60)
    }
    
    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saldo Disponível")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(financialData?.formattedAvailableBalance ?? "R$ 0,00")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                // Withdraw button
                Button(action: {
                    showingWithdrawSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text("Sacar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.8),
                                Color.green.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .disabled((financialData?.availableBalance ?? 0) <= 0)
            }
            
            // Additional info
            HStack {
                InfoPill(
                    icon: "clock.fill",
                    text: "Próximo saque: \(financialData?.nextPayoutDate ?? "N/A")",
                    color: .blue
                )
                
                Spacer()
                
                InfoPill(
                    icon: "percent",
                    text: "Taxa: \(financialData?.platformFeePercentage ?? 0)%",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.2),
            radius: 20,
            x: 0,
            y: 10
        )
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateCards)
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Receita Total",
                value: financialData?.formattedTotalRevenue ?? "R$ 0,00",
                icon: "dollarsign.circle.fill",
                color: .green,
                trend: financialData?.revenueTrend,
                animateCards: animateCards,
                delay: 0.2
            )
            
            StatCard(
                title: "Pacientes Ativos",
                value: "\(financialData?.activePatients ?? 0)",
                icon: "person.3.fill",
                color: .blue,
                trend: financialData?.patientsTrend,
                animateCards: animateCards,
                delay: 0.3
            )
            
            StatCard(
                title: "Receita Mensal",
                value: financialData?.formattedMonthlyRevenue ?? "R$ 0,00",
                icon: "calendar.circle.fill",
                color: Color(red: 0.4, green: 0.2, blue: 0.8),
                trend: financialData?.monthlyTrend,
                animateCards: animateCards,
                delay: 0.4
            )
            
            StatCard(
                title: "Taxa Conversão",
                value: financialData?.formattedConversionRate ?? "0%",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange,
                trend: financialData?.conversionTrend,
                animateCards: animateCards,
                delay: 0.5
            )
        }
    }
    
    private var revenueChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Receita dos Últimos Meses")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let chartData = financialData?.revenueChartData, !chartData.isEmpty {
                Chart(chartData) { item in
                    LineMark(
                        x: .value("Mês", item.month),
                        y: .value("Receita", item.revenue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                Color(red: 0.2, green: 0.6, blue: 0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Mês", item.month),
                        y: .value("Receita", item.revenue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                                Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            } else {
                EmptyChartView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateCards)
    }
    
    private var patientPaymentsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Pagamentos de Pacientes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Ver Todos") {
                    // Navigate to full payments list
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.8))
            }
            
            if let payments = financialData?.recentPayments, !payments.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(payments.prefix(5)) { payment in
                        PatientPaymentRow(payment: payment)
                    }
                }
            } else {
                EmptyPaymentsView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: animateCards)
    }
    
    private var withdrawalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Histórico de Saques")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let withdrawals = financialData?.recentWithdrawals, !withdrawals.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(withdrawals.prefix(3)) { withdrawal in
                        WithdrawalRow(withdrawal: withdrawal)
                    }
                }
            } else {
                EmptyWithdrawalsView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateCards)
    }
    
    private var recentTransactionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Transações Recentes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let transactions = financialData?.recentTransactions, !transactions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(transactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            } else {
                EmptyTransactionsView()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.9), value: animateCards)
    }
    
    private func loadFinancialData() {
        isLoading = true
        
        Task {
            do {
                let data = try await stripeManager.getFinancialData(period: selectedPeriod)
                
                DispatchQueue.main.async {
                    self.financialData = data
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Handle error
                    print("Erro ao carregar dados financeiros: \(error)")
                }
            }
        }
    }
    
    private func refreshData() async {
        await MainActor.run {
            loadFinancialData()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateCards = true
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            pulseAnimation = true
        }
        
        // Start particle animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                particleOffset += 1
            }
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendData?
    let animateCards: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .scaleEffect(animateCards ? 1.0 : 0.9)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateCards)
    }
}

struct TrendIndicator: View {
    let trend: TrendData
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.isPositive ? "arrow.up" : "arrow.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(trend.isPositive ? .green : .red)
            
            Text(trend.formattedPercentage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(trend.isPositive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((trend.isPositive ? Color.green : Color.red).opacity(0.2))
        )
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct PatientPaymentRow: View {
    let payment: PatientPayment
    
    var body: some View {
        HStack(spacing: 12) {
            // Patient avatar
            Circle()
                .fill(Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(payment.patientInitials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Payment info
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.patientName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(payment.formattedDate)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Amount and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                PaymentStatusBadge(status: payment.status)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PaymentStatusBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.3))
            .clipShape(Capsule())
    }
}

struct WithdrawalRow: View {
    let withdrawal: Withdrawal
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Saque")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(withdrawal.formattedDate)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(withdrawal.formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                WithdrawalStatusBadge(status: withdrawal.status)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WithdrawalStatusBadge: View {
    let status: WithdrawalStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.3))
            .clipShape(Capsule())
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.icon)
                .font(.system(size: 20))
                .foregroundColor(transaction.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(transaction.formattedDate)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(transaction.isPositive ? .green : .red)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Empty State Views
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Dados insuficientes")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Complete mais transações para ver o gráfico")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

struct EmptyPaymentsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Nenhum pagamento ainda")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 100)
    }
}

struct EmptyWithdrawalsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Nenhum saque realizado")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 100)
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Nenhuma transação")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 100)
    }
}

// MARK: - Background Views
struct FinancialBackgroundView: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.1),
                    Color.clear,
                    Color.green.opacity(0.1)
                ]),
                startPoint: animateGradient ? .topTrailing : .bottomLeading,
                endPoint: animateGradient ? .bottomLeading : .topTrailing
            )
            .animation(
                Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
        }
        .ignoresSafeArea()
    }
}

struct FinancialParticlesView: View {
    @Binding var offset: CGFloat
    @State private var particles: [FinancialParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(offset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(offset * particle.speed * 0.7) * particle.amplitude * 0.3
                        )
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            FinancialParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...4),
                color: [
                    Color.green.opacity(0.3),
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.2),
                    Color.white.opacity(0.1)
                ].randomElement()!,
                speed: Double.random(in: 0.005...0.02),
                amplitude: CGFloat.random(in: 15...40),
                opacity: Double.random(in: 0.2...0.6),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
}

struct FinancialParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let speed: Double
    let amplitude: CGFloat
    let opacity: Double
    let blur: CGFloat
}

#Preview {
    FinancialDashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(StripeManager())
        .environmentObject(InvitationManager())
}
