//
//  StripeKeysConfigurationView.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct StripeKeysConfigurationView: View {
    @StateObject private var securityManager = StripeSecurityManager.shared
    @State private var selectedEnvironment: BuildEnvironment = .development
    @State private var publishableKey = ""
    @State private var secretKey = ""
    @State private var webhookSecret = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingAudit = false
    @State private var securityAudit: StripeSecurityAudit?
    
    var body: some View {
        NavigationView {
            Form {
                environmentSection
                keysSection
                actionsSection
                securitySection
            }
            .navigationTitle("Configuração Stripe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Auditoria") {
                        performSecurityAudit()
                    }
                }
            }
        }
        .alert("Configuração", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingAudit) {
            if let audit = securityAudit {
                SecurityAuditView(audit: audit)
            }
        }
        .onAppear {
            loadCurrentKeys()
        }
    }
    
    private var environmentSection: some View {
        Section("Ambiente") {
            Picker("Selecionar Ambiente", selection: $selectedEnvironment) {
                ForEach(BuildEnvironment.allCases, id: \.self) { environment in
                    Text(environment.displayName).tag(environment)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedEnvironment) { _ in
                loadCurrentKeys()
            }
            
            HStack {
                Image(systemName: environmentIcon)
                    .foregroundColor(environmentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ambiente Atual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(selectedEnvironment.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if securityManager.isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var keysSection: some View {
        Section("Chaves do Stripe") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chave Publicável")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("pk_test_... ou pk_live_...", text: $publishableKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Chave Secreta")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("sk_test_... ou sk_live_...", text: $secretKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Segredo do Webhook")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("whsec_...", text: $webhookSecret)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
    }
    
    private var actionsSection: some View {
        Section("Ações") {
            Button(action: saveKeys) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "lock.fill")
                    }
                    
                    Text("Salvar Chaves")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isLoading || !areKeysValid)
            .buttonStyle(PlainButtonStyle())
            
            Button(action: clearKeys) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Limpar Todas as Chaves")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var securitySection: some View {
        Section("Segurança") {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Criptografia")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("AES-256-GCM com chave específica do dispositivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Armazenamento")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Keychain com proteção de dispositivo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auditoria")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Log de todas as operações de segurança")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Ver Auditoria") {
                    performSecurityAudit()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var environmentIcon: String {
        switch selectedEnvironment {
        case .development:
            return "hammer.circle.fill"
        case .staging:
            return "testtube.2"
        case .production:
            return "globe"
        }
    }
    
    private var environmentColor: Color {
        switch selectedEnvironment {
        case .development:
            return .blue
        case .staging:
            return .orange
        case .production:
            return .red
        }
    }
    
    private var areKeysValid: Bool {
        !publishableKey.isEmpty && !secretKey.isEmpty && !webhookSecret.isEmpty
    }
    
    private func loadCurrentKeys() {
        // Limpar campos ao trocar de ambiente
        publishableKey = ""
        secretKey = ""
        webhookSecret = ""
        
        // Tentar carregar chaves existentes (apenas para verificação, não exibir)
        do {
            _ = try securityManager.getStripeKey(type: .publishable, environment: selectedEnvironment)
            _ = try securityManager.getStripeKey(type: .secret, environment: selectedEnvironment)
            _ = try securityManager.getStripeKey(type: .webhook, environment: selectedEnvironment)
            
            // Se chegou até aqui, as chaves existem
            publishableKey = "••••••••••••••••"
            secretKey = "••••••••••••••••"
            webhookSecret = "••••••••••••••••"
        } catch {
            // Chaves não existem, campos ficam vazios
        }
    }
    
    private func saveKeys() {
        isLoading = true
        
        Task {
            do {
                // Salvar cada chave
                try securityManager.storeStripeKey(
                    publishableKey,
                    type: .publishable,
                    environment: selectedEnvironment
                )
                
                try securityManager.storeStripeKey(
                    secretKey,
                    type: .secret,
                    environment: selectedEnvironment
                )
                
                try securityManager.storeStripeKey(
                    webhookSecret,
                    type: .webhook,
                    environment: selectedEnvironment
                )
                
                await MainActor.run {
                    alertMessage = "Chaves salvas com sucesso!"
                    showingAlert = true
                    isLoading = false
                    
                    // Limpar campos após salvar
                    publishableKey = ""
                    secretKey = ""
                    webhookSecret = ""
                    
                    loadCurrentKeys()
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "Erro ao salvar chaves: \(error.localizedDescription)"
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func clearKeys() {
        securityManager.clearAllStripeKeys()
        loadCurrentKeys()
        
        alertMessage = "Todas as chaves foram removidas"
        showingAlert = true
    }
    
    private func performSecurityAudit() {
        securityAudit = securityManager.performSecurityAudit()
        showingAudit = true
    }
}

// MARK: - Security Audit View

struct SecurityAuditView: View {
    let audit: StripeSecurityAudit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Status Geral") {
                    HStack {
                        Image(systemName: audit.isSecure ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(audit.isSecure ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Status de Segurança")
                                .font(.headline)
                            
                            Text(audit.isSecure ? "Seguro" : "Requer Atenção")
                                .font(.subheadline)
                                .foregroundColor(audit.isSecure ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Text(audit.auditDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !audit.validKeys.isEmpty {
                    Section("Chaves Válidas") {
                        ForEach(audit.validKeys, id: \.0.rawValue) { keyType, environment in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("\(keyType.displayName) - \(environment.displayName)")
                            }
                        }
                    }
                }
                
                if !audit.invalidKeys.isEmpty {
                    Section("Chaves Inválidas") {
                        ForEach(audit.invalidKeys, id: \.0.rawValue) { keyType, environment in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                
                                Text("\(keyType.displayName) - \(environment.displayName)")
                            }
                        }
                    }
                }
                
                if !audit.missingKeys.isEmpty {
                    Section("Chaves Ausentes") {
                        ForEach(audit.missingKeys, id: \.0.rawValue) { keyType, environment in
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.orange)
                                
                                Text("\(keyType.displayName) - \(environment.displayName)")
                            }
                        }
                    }
                }
                
                if !audit.securityWarnings.isEmpty {
                    Section("Avisos de Segurança") {
                        ForEach(audit.securityWarnings, id: \.self) { warning in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                
                                Text(warning)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Auditoria de Segurança")
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

// MARK: - Preview

struct StripeKeysConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        StripeKeysConfigurationView()
    }
}
