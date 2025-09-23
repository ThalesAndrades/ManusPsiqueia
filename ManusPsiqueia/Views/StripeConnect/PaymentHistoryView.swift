//
//  PaymentHistoryView.swift
//  ManusPsiqueia
//
//  Created by Manus AI on 2025-09-23.
//  Copyright © 2025 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct PaymentHistoryView: View {
    @StateObject private var paymentService = SessionPaymentService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: PaymentFilter = .all
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    
    let psychologist: User
    
    private var filteredPayments: [SessionPayment] {
        let payments = paymentService.getPaymentHistory(
            for: psychologist.id.uuidString,
            userType: .psychologist
        )
        
        var filtered = payments
        
        // Aplicar filtro de status
        switch selectedFilter {
        case .all:
            break
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .pending:
            filtered = filtered.filter { $0.status == .processing }
        case .refunded:
            filtered = filtered.filter { $0.status == .refunded }
        }
        
        // Aplicar busca por texto
        if !searchText.isEmpty {
            filtered = filtered.filter { payment in
                payment.description.localizedCaseInsensitiveContains(searchText) ||
                payment.formattedAmount.contains(searchText)
            }
        }
        
        return filtered.sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterSection
                
                if filteredPayments.isEmpty {
                    emptyStateView
                } else {
                    paymentsList
                }
            }
            .navigationTitle("Histórico de Pagamentos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filtros") {
                        showingFilterSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(selectedFilter: $selectedFilter)
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Barra de busca
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar pagamentos...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Limpar") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filtros rápidos
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PaymentFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var paymentsList: some View {
        List {
            ForEach(groupedPayments, id: \.key) { group in
                Section(header: Text(group.key)) {
                    ForEach(group.value, id: \.id) { payment in
                        PaymentHistoryRow(payment: payment)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Nenhum pagamento encontrado")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Seus pagamentos aparecerão aqui quando você começar a receber pelos seus serviços.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Limpar Filtros") {
                selectedFilter = .all
                searchText = ""
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var groupedPayments: [(key: String, value: [SessionPayment])] {
        let grouped = Dictionary(grouping: filteredPayments) { payment in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "pt_BR")
            return formatter.string(from: payment.scheduledDate).capitalized
        }
        
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "pt_BR")
            
            guard let firstDate = formatter.date(from: first.key.lowercased()),
                  let secondDate = formatter.date(from: second.key.lowercased()) else {
                return false
            }
            
            return firstDate > secondDate
        }
    }
}

// MARK: - Supporting Views

struct PaymentHistoryRow: View {
    let payment: SessionPayment
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(payment.status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    Label(
                        payment.scheduledDate.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Label(
                        payment.paymentMethod.displayName,
                        systemImage: payment.paymentMethod.icon
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
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
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterSheet: View {
    @Binding var selectedFilter: PaymentFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Status do Pagamento") {
                    ForEach(PaymentFilter.allCases, id: \.self) { filter in
                        HStack {
                            Text(filter.displayName)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFilter = filter
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
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

// MARK: - Filter Enum

enum PaymentFilter: CaseIterable {
    case all
    case completed
    case pending
    case refunded
    
    var displayName: String {
        switch self {
        case .all:
            return "Todos"
        case .completed:
            return "Concluídos"
        case .pending:
            return "Pendentes"
        case .refunded:
            return "Reembolsados"
        }
    }
}

// MARK: - Preview

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView(
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
