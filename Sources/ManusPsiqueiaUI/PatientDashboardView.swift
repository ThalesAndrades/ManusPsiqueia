import ManusPsiqueiaCore
//
//  PatientDashboardView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct PatientDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                PatientHomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Início")
                    }
                    .tag(0)
                
                // Sessions Tab
                SessionsView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Sessões")
                    }
                    .tag(1)
                
                // Progress Tab
                ProgressView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progresso")
                    }
                    .tag(2)
                
                // Profile Tab
                PatientProfileView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Perfil")
                    }
                    .tag(3)
            }
            .navigationTitle("Meu Espaço")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sair") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

public struct PatientHomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bem-vindo(a) de volta!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Como você está se sentindo hoje?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Quick Actions
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    QuickActionCard(
                        icon: "calendar.badge.plus",
                        title: "Agendar Sessão",
                        subtitle: "Nova consulta",
                        color: .blue
                    )
                    
                    QuickActionCard(
                        icon: "heart.text.square",
                        title: "Diário Emocional",
                        subtitle: "Registrar sentimentos",
                        color: .pink
                    )
                    
                    QuickActionCard(
                        icon: "message.circle",
                        title: "Conversar",
                        subtitle: "Chat com psicólogo",
                        color: .green
                    )
                    
                    QuickActionCard(
                        icon: "book.circle",
                        title: "Recursos",
                        subtitle: "Materiais de apoio",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 16) {
                    Text("Atividade Recente")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ActivityRow(
                            icon: "checkmark.circle.fill",
                            title: "Sessão concluída",
                            subtitle: "Há 2 dias",
                            color: .green
                        )
                        
                        ActivityRow(
                            icon: "heart.fill",
                            title: "Diário atualizado",
                            subtitle: "Há 3 dias",
                            color: .pink
                        )
                        
                        ActivityRow(
                            icon: "calendar",
                            title: "Próxima sessão agendada",
                            subtitle: "Em 2 dias",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top)
        }
    }
}

public struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

public struct SessionsView: View {
    var body: some View {
        VStack {
            Text("Suas Sessões")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Funcionalidade em desenvolvimento")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

public struct ProgressView: View {
    var body: some View {
        VStack {
            Text("Seu Progresso")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Funcionalidade em desenvolvimento")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

public struct PatientProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Header
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text(authManager.currentUser?.email ?? "Usuário")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Paciente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Profile Options
            VStack(spacing: 16) {
                ProfileOptionRow(icon: "gear", title: "Configurações", action: {})
                ProfileOptionRow(icon: "bell", title: "Notificações", action: {})
                ProfileOptionRow(icon: "shield", title: "Privacidade", action: {})
                ProfileOptionRow(icon: "questionmark.circle", title: "Ajuda", action: {})
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Sign Out Button
            Button(action: {
                authManager.signOut()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Sair da Conta")
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.large)
    }
}

public struct PatientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDashboardView()
            .environmentObject(AuthenticationManager())
    }
}
