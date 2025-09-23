//
//  ConnectOnboardingView.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import SafariServices

struct ConnectOnboardingView: View {
    @StateObject private var connectManager = StripeConnectManager.shared
    @State private var showingSafari = false
    @State private var onboardingURL: URL?
    @State private var showingError = false
    
    let psychologist: User
    let onCompletion: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    requirementsSection
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Configurar Pagamentos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Pular") {
                        onCompletion()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let url = onboardingURL {
                SafariView(url: url) { result in
                    handleOnboardingResult(result)
                }
            }
        }
        .alert("Erro", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(connectManager.errorMessage ?? "Erro desconhecido")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Receba Pagamentos")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Configure sua conta para receber pagamentos dos seus pacientes de forma segura e automática.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefícios")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "bolt.circle.fill",
                    title: "Pagamentos Automáticos",
                    description: "Receba automaticamente após cada sessão"
                )
                
                BenefitRow(
                    icon: "shield.checkered",
                    title: "Segurança Garantida",
                    description: "Proteção PCI DSS e criptografia de ponta"
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Relatórios Detalhados",
                    description: "Acompanhe seus ganhos e histórico"
                )
                
                BenefitRow(
                    icon: "banknote",
                    title: "Transferências Rápidas",
                    description: "Dinheiro na sua conta em até 2 dias úteis"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documentos Necessários")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                RequirementRow(text: "CPF ou CNPJ")
                RequirementRow(text: "Dados bancários completos")
                RequirementRow(text: "Comprovante de endereço")
                RequirementRow(text: "Documento de identidade")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: startOnboarding) {
                HStack {
                    if connectManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    
                    Text("Configurar Conta")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(connectManager.isLoading)
            
            Text("Ao continuar, você será redirecionado para o Stripe para completar a configuração da sua conta.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func startOnboarding() {
        Task {
            do {
                // Criar conta conectada
                let accountId = try await connectManager.createConnectedAccount(for: psychologist)
                
                // Criar link de onboarding
                let returnURL = "manuspsiqueia://stripe-onboarding-return"
                let refreshURL = "manuspsiqueia://stripe-onboarding-refresh"
                
                let urlString = try await connectManager.createAccountLink(
                    accountId: accountId,
                    returnURL: returnURL,
                    refreshURL: refreshURL
                )
                
                onboardingURL = URL(string: urlString)
                showingSafari = true
                
            } catch {
                connectManager.errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func handleOnboardingResult(_ result: SafariViewResult) {
        switch result {
        case .completed:
            // Verificar status da conta
            Task {
                // Aguardar um pouco para o Stripe processar
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
                
                // Verificar se o onboarding foi concluído
                // Em uma implementação real, você verificaria o status da conta
                onCompletion()
            }
        case .cancelled:
            // Usuário cancelou o onboarding
            break
        }
    }
}

// MARK: - Supporting Views

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct RequirementRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: (SafariViewResult) -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.delegate = context.coordinator
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: (SafariViewResult) -> Void
        
        init(onDismiss: @escaping (SafariViewResult) -> Void) {
            self.onDismiss = onDismiss
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDismiss(.cancelled)
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if didLoadSuccessfully {
                // Verificar se a URL indica conclusão do onboarding
                if let url = controller.url, url.absoluteString.contains("return") {
                    onDismiss(.completed)
                }
            }
        }
    }
}

enum SafariViewResult {
    case completed
    case cancelled
}

// MARK: - Preview

struct ConnectOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectOnboardingView(
            psychologist: User(
                id: UUID(),
                email: "psicologo@exemplo.com",
                fullName: "Dr. João Silva",
                userType: .psychologist,
                isActive: true,
                createdAt: Date(),
                lastLoginAt: Date()
            ),
            onCompletion: {}
        )
    }
}
