//
//  WithdrawFundsView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct WithdrawFundsView: View {
    @EnvironmentObject var stripeManager: StripeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var withdrawAmount = ""
    @State private var selectedBankAccount: BankAccount?
    @State private var availableBankAccounts: [BankAccount] = []
    @State private var showingAddBankAccount = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var particleOffset: CGFloat = 0
    
    // Mock data for available balance
    @State private var availableBalance: Decimal = 2450.80
    private let minimumWithdrawAmount: Decimal = 50.00
    private let platformFee: Decimal = 0.025 // 2.5%
    
    var withdrawAmountDecimal: Decimal {
        return Decimal(string: withdrawAmount) ?? 0
    }
    
    var calculatedFee: Decimal {
        return withdrawAmountDecimal * platformFee
    }
    
    var netAmount: Decimal {
        return withdrawAmountDecimal - calculatedFee
    }
    
    var isValidAmount: Bool {
        return withdrawAmountDecimal >= minimumWithdrawAmount &&
               withdrawAmountDecimal <= availableBalance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                WithdrawBackgroundView(animateGradient: $animateGradient)
                
                // Floating particles
                WithdrawParticlesView(offset: $particleOffset)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header info
                        headerSection
                        
                        // Available balance
                        balanceSection
                        
                        // Amount input
                        amountInputSection
                        
                        // Bank account selection
                        bankAccountSection
                        
                        // Fee breakdown
                        feeBreakdownSection
                        
                        // Withdraw button
                        withdrawButtonSection
                        
                        // Info section
                        infoSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Sacar Fundos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            startAnimations()
            loadBankAccounts()
        }
        .sheet(isPresented: $showingAddBankAccount) {
            AddBankAccountView()
                .environmentObject(stripeManager)
        }
        .alert("Erro", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Sucesso!", isPresented: .constant(successMessage != nil)) {
            Button("OK") {
                successMessage = nil
                dismiss()
            }
        } message: {
            if let successMessage = successMessage {
                Text(successMessage)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.4),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.green)
            }
            
            // Title and description
            VStack(spacing: 8) {
                Text("Sacar Fundos")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Transfira seus ganhos para sua conta bancária")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private var balanceSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Saldo Disponível")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            HStack {
                Text(formatCurrency(availableBalance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Próximo saque")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("15 de Janeiro")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
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
    }
    
    private var amountInputSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Valor do Saque")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Amount input
                HStack {
                    Text("R$")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("0,00", text: $withdrawAmount)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .onChange(of: withdrawAmount) { newValue in
                            // Format input to currency
                            let filtered = newValue.filter { "0123456789,".contains($0) }
                            if filtered != newValue {
                                withdrawAmount = filtered
                            }
                        }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isValidAmount ? Color.green.opacity(0.5) : Color.white.opacity(0.2),
                                    lineWidth: isValidAmount ? 2 : 1
                                )
                        )
                )
                
                // Quick amount buttons
                HStack(spacing: 12) {
                    QuickAmountButton(amount: 100, currentAmount: $withdrawAmount)
                    QuickAmountButton(amount: 500, currentAmount: $withdrawAmount)
                    QuickAmountButton(amount: 1000, currentAmount: $withdrawAmount)
                    
                    Button(action: {
                        withdrawAmount = String(describing: availableBalance)
                    }) {
                        Text("Máximo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                
                // Validation messages
                if !withdrawAmount.isEmpty {
                    VStack(spacing: 8) {
                        if withdrawAmountDecimal < minimumWithdrawAmount {
                            ValidationMessage(
                                text: "Valor mínimo: \(formatCurrency(minimumWithdrawAmount))",
                                isError: true
                            )
                        } else if withdrawAmountDecimal > availableBalance {
                            ValidationMessage(
                                text: "Valor excede saldo disponível",
                                isError: true
                            )
                        } else {
                            ValidationMessage(
                                text: "Valor válido para saque",
                                isError: false
                            )
                        }
                    }
                }
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
    }
    
    private var bankAccountSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Conta de Destino")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showingAddBankAccount = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text("Adicionar")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Capsule())
                }
            }
            
            if availableBankAccounts.isEmpty {
                EmptyBankAccountsView {
                    showingAddBankAccount = true
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(availableBankAccounts) { account in
                        BankAccountRow(
                            account: account,
                            isSelected: selectedBankAccount?.id == account.id
                        ) {
                            selectedBankAccount = account
                        }
                    }
                }
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
    }
    
    private var feeBreakdownSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumo do Saque")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if withdrawAmountDecimal > 0 {
                VStack(spacing: 12) {
                    FeeRow(
                        title: "Valor solicitado",
                        amount: withdrawAmountDecimal,
                        isPositive: false
                    )
                    
                    FeeRow(
                        title: "Taxa da plataforma (2,5%)",
                        amount: calculatedFee,
                        isPositive: false
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    FeeRow(
                        title: "Valor líquido",
                        amount: netAmount,
                        isPositive: true,
                        isBold: true
                    )
                    
                    // Estimated arrival
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Chegada estimada: 1-2 dias úteis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Digite um valor para ver o resumo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 100)
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
    }
    
    private var withdrawButtonSection: some View {
        Button(action: {
            processWithdrawal()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text(isLoading ? "Processando..." : "Confirmar Saque")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if canProcessWithdrawal && !isLoading {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green,
                                Color.green.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(
                color: canProcessWithdrawal && !isLoading ? 
                    Color.green.opacity(0.4) : 
                    Color.clear,
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .disabled(!canProcessWithdrawal || isLoading)
        .scaleEffect(canProcessWithdrawal && pulseAnimation ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: pulseAnimation
        )
    }
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            InfoCard(
                icon: "shield.checkered",
                title: "Segurança",
                description: "Todas as transferências são processadas com segurança através do Stripe",
                color: .blue
            )
            
            InfoCard(
                icon: "clock.fill",
                title: "Processamento",
                description: "Saques são processados em 1-2 dias úteis",
                color: .orange
            )
            
            InfoCard(
                icon: "percent",
                title: "Taxas",
                description: "Taxa de 2,5% sobre o valor sacado para cobrir custos de processamento",
                color: .purple
            )
        }
    }
    
    private var canProcessWithdrawal: Bool {
        return isValidAmount &&
               selectedBankAccount != nil &&
               !withdrawAmount.isEmpty
    }
    
    private func loadBankAccounts() {
        // Mock data - in real app, load from API
        availableBankAccounts = [BankAccount.mock]
        selectedBankAccount = availableBankAccounts.first
    }
    
    private func processWithdrawal() {
        guard let bankAccount = selectedBankAccount else { return }
        
        isLoading = true
        
        Task {
            do {
                let withdrawal = try await stripeManager.processWithdrawal(
                    amount: withdrawAmountDecimal,
                    bankAccount: bankAccount
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.successMessage = "Saque de \(self.formatCurrency(withdrawal.netAmount)) processado com sucesso!"
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Erro ao processar saque: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animateGradient = true
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
struct QuickAmountButton: View {
    let amount: Int
    @Binding var currentAmount: String
    
    var body: some View {
        Button(action: {
            currentAmount = String(amount)
        }) {
            Text("R$ \(amount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

struct ValidationMessage: View {
    let text: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(isError ? .red : .green)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isError ? .red : .green)
            
            Spacer()
        }
    }
}

struct BankAccountRow: View {
    let account: BankAccount
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Bank icon
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                // Account info
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.bankName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(account.accountType.displayName) \(account.maskedAccountNumber)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if account.isDefault {
                        Text("Conta padrão")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.green.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyBankAccountsView: View {
    let onAddAccount: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Nenhuma conta bancária")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Adicione uma conta bancária para receber seus saques")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: onAddAccount) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("Adicionar Conta")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.6))
                .clipShape(Capsule())
            }
        }
        .frame(height: 200)
    }
}

struct FeeRow: View {
    let title: String
    let amount: Decimal
    let isPositive: Bool
    let isBold: Bool
    
    init(title: String, amount: Decimal, isPositive: Bool, isBold: Bool = false) {
        self.title = title
        self.amount = amount
        self.isPositive = isPositive
        self.isBold = isBold
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .medium))
                .foregroundColor(.white.opacity(isBold ? 1.0 : 0.8))
            
            Spacer()
            
            Text(formatCurrency(amount))
                .font(.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .medium))
                .foregroundColor(isBold ? .white : .white.opacity(0.8))
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: amount as NSDecimalNumber) ?? "R$ 0,00"
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Background Views
struct WithdrawBackgroundView: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.1, blue: 0.05),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.1),
                    Color.clear,
                    Color.blue.opacity(0.1)
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

struct WithdrawParticlesView: View {
    @Binding var offset: CGFloat
    @State private var particles: [WithdrawParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(offset * particle.speed) * particle.amplitude,
                            y: particle.y + cos(offset * particle.speed * 0.6) * particle.amplitude * 0.4
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
        particles = (0..<15).map { _ in
            WithdrawParticle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...4),
                color: [
                    Color.green.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.white.opacity(0.1)
                ].randomElement()!,
                speed: Double.random(in: 0.008...0.025),
                amplitude: CGFloat.random(in: 20...50),
                opacity: Double.random(in: 0.3...0.6),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
}

struct WithdrawParticle: Identifiable {
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

// MARK: - Add Bank Account View (Placeholder)
struct AddBankAccountView: View {
    @EnvironmentObject var stripeManager: StripeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Adicionar Conta Bancária")
                    .font(.title2)
                    .padding()
                
                Text("Implementar formulário para adicionar conta bancária")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Nova Conta")
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

#Preview {
    WithdrawFundsView()
        .environmentObject(StripeManager())
}
