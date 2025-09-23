//
//  RegistrationView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct RegistrationView: View {
    let userType: UserType
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var agreeToTerms = false
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName, email, password, confirmPassword, phone
    }
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Criar Conta",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    headerSection
                    
                    // Form
                    formSection
                    
                    // Terms agreement
                    termsSection
                    
                    // Register button
                    registerButton
                    
                    // Login option
                    loginSection
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background)
        }
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authManager.isAuthenticated) { authenticated in
            if authenticated {
                dismiss()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // User type indicator
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                userType.color.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: userType.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(userType.color)
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Criar conta como \(userType.displayName)")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.label)
                    .multilineTextAlignment(.center)
                
                Text(userType.description)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Name fields
            HStack(spacing: DesignSystem.Spacing.sm) {
                AppleStyleTextField(
                    title: "Nome",
                    text: $firstName,
                    placeholder: "Seu nome",
                    autocapitalization: .words,
                    accessibilityHint: "Digite seu primeiro nome"
                )
                .focused($focusedField, equals: .firstName)
                .onSubmit {
                    focusedField = .lastName
                }
                
                AppleStyleTextField(
                    title: "Sobrenome",
                    text: $lastName,
                    placeholder: "Seu sobrenome",
                    autocapitalization: .words,
                    accessibilityHint: "Digite seu sobrenome"
                )
                .focused($focusedField, equals: .lastName)
                .onSubmit {
                    focusedField = .email
                }
            }
            
            // Email field
            AppleStyleTextField(
                title: "Email",
                text: $email,
                placeholder: "seu@email.com",
                keyboardType: .emailAddress,
                autocapitalization: .never,
                accessibilityHint: "Digite seu endereço de email"
            )
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .password
            }
            
            // Phone field (optional)
            AppleStyleTextField(
                title: "Telefone (opcional)",
                text: $phone,
                placeholder: "(11) 99999-9999",
                keyboardType: .phonePad,
                accessibilityHint: "Digite seu número de telefone (opcional)"
            )
            .focused($focusedField, equals: .phone)
            .onSubmit {
                focusedField = .password
            }
            
            // Password fields
            passwordField
            confirmPasswordField
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Senha")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.label)
                .fontWeight(.medium)
            
            HStack {
                Group {
                    if showPassword {
                        TextField("Digite sua senha", text: $password)
                    } else {
                        SecureField("Digite sua senha", text: $password)
                    }
                }
                .font(DesignSystem.Typography.body)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    focusedField = .confirmPassword
                }
                
                Button(action: {
                    showPassword.toggle()
                    DesignSystem.Haptics.light()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                .accessibilityLabel(showPassword ? "Ocultar senha" : "Mostrar senha")
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        focusedField == .password ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                        lineWidth: focusedField == .password ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            
            // Password requirements
            VStack(alignment: .leading, spacing: 2) {
                PasswordRequirement(
                    text: "Mínimo 8 caracteres",
                    isValid: password.count >= 8
                )
            }
            .padding(.top, 4)
        }
    }
    
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Confirmar Senha")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.label)
                .fontWeight(.medium)
            
            HStack {
                Group {
                    if showConfirmPassword {
                        TextField("Confirme sua senha", text: $confirmPassword)
                    } else {
                        SecureField("Confirme sua senha", text: $confirmPassword)
                    }
                }
                .font(DesignSystem.Typography.body)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .confirmPassword)
                .onSubmit {
                    registerUser()
                }
                
                Button(action: {
                    showConfirmPassword.toggle()
                    DesignSystem.Haptics.light()
                }) {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                .accessibilityLabel(showConfirmPassword ? "Ocultar confirmação" : "Mostrar confirmação")
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        focusedField == .confirmPassword ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                        lineWidth: focusedField == .confirmPassword ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            
            // Password match indicator
            if !confirmPassword.isEmpty {
                PasswordRequirement(
                    text: "Senhas coincidem",
                    isValid: password == confirmPassword
                )
                .padding(.top, 4)
            }
        }
    }
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Button(action: {
                agreeToTerms.toggle()
                DesignSystem.Haptics.selection()
            }) {
                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(agreeToTerms ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryLabel)
            }
            .accessibilityRole(.checkbox)
            .accessibilityLabel("Aceitar termos")
            .accessibilityValue(agreeToTerms ? "Marcado" : "Desmarcado")
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Aceito os ")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                +
                Text("Termos de Uso")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .underline()
                +
                Text(" e ")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                +
                Text("Política de Privacidade")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .underline()
            }
            .onTapGesture {
                // Navigate to terms and privacy policy
                navigationManager.navigate(to: .termsOfService)
            }
            
            Spacer()
        }
    }
    
    private var registerButton: some View {
        Button(action: registerUser) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Criar Conta")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isFormValid || isLoading)
        .accessibilityLabel("Criar conta")
        .accessibilityHint("Cria sua conta no ManusPsiqueia")
    }
    
    private var loginSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(height: 1)
                
                Text("ou")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(height: 1)
            }
            
            // Login button
            Button(action: {
                dismiss()
                // Navigate to login
            }) {
                Text("Já tenho uma conta")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .underline()
            }
            .accessibilityLabel("Fazer login")
            .accessibilityHint("Já tenho uma conta, fazer login")
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               authManager.isValidEmail(email) &&
               authManager.isValidPassword(password) &&
               password == confirmPassword &&
               agreeToTerms
    }
    
    // MARK: - Methods
    private func registerUser() {
        guard isFormValid else {
            errorMessage = "Por favor, preencha todos os campos corretamente"
            showError = true
            return
        }
        
        focusedField = nil
        isLoading = true
        
        let user = User(
            email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            userType: userType,
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            await authManager.register(user: user, password: password)
            
            await MainActor.run {
                isLoading = false
                
                if !authManager.isAuthenticated {
                    errorMessage = authManager.authenticationError?.localizedDescription ?? "Erro ao criar conta"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Password Requirement Component
struct PasswordRequirement: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(isValid ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            
            Text(text)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(isValid ? DesignSystem.Colors.success : DesignSystem.Colors.error)
            
            Spacer()
        }
    }
}

#Preview {
    RegistrationView(userType: .patient)
        .environmentObject(AuthenticationManager())
        .environmentObject(NavigationManager.shared)
}