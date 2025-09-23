//
//  PsychologistDashboardView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct PsychologistDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Patients Tab
                PatientManagementDashboard()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Pacientes")
                    }
                    .tag(0)
                
                // Financial Tab
                FinancialDashboardView()
                    .tabItem {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Financeiro")
                    }
                    .tag(1)
                
                // Invitations Tab
                InvitePsychologistView()
                    .tabItem {
                        Image(systemName: "envelope.fill")
                        Text("Convites")
                    }
                    .tag(2)
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Perfil")
                    }
                    .tag(3)
            }
            .navigationTitle("Dashboard")
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

struct ProfileView: View {
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
                
                Text("Psicólogo(a)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Profile Options
            VStack(spacing: 16) {
                ProfileOptionRow(icon: "gear", title: "Configurações", action: {})
                ProfileOptionRow(icon: "bell", title: "Notificações", action: {})
                ProfileOptionRow(icon: "questionmark.circle", title: "Ajuda", action: {})
                ProfileOptionRow(icon: "info.circle", title: "Sobre", action: {})
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

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PsychologistDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PsychologistDashboardView()
            .environmentObject(AuthenticationManager())
    }
}
