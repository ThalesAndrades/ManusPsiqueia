import ManusPsiqueiaCore
//
//  AuthenticationView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("ManusPsiqueia")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(isSignUp ? "Criar conta" : "Entrar na sua conta")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 40)
                
                // Authentication form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Digite seu email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Senha")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        SecureField("Digite sua senha", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Action button
                    Button(action: authenticate) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSignUp ? "Criar Conta" : "Entrar")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    // Toggle between sign in and sign up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSignUp.toggle()
                        }
                    }) {
                        Text(isSignUp ? "Já tem uma conta? Entrar" : "Não tem conta? Criar uma")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .alert("Erro", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func authenticate() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        
        // Simulate authentication process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if isSignUp {
                // Simulate sign up
                authManager.signUp(email: email, password: password) { success, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if !success {
                            alertMessage = error ?? "Erro ao criar conta"
                            showingAlert = true
                        }
                    }
                }
            } else {
                // Simulate sign in
                authManager.signIn(email: email, password: password) { success, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if !success {
                            alertMessage = error ?? "Erro ao fazer login"
                            showingAlert = true
                        }
                    }
                }
            }
        }
    }
}

public struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationManager())
    }
}
