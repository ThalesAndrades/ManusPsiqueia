//
//  PaymentHistoryView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct PaymentHistoryView: View {
    @StateObject private var viewModel = PaymentViewModel()
    @State private var payments: [PatientPayment] = []
    @State private var selectedFilter: PaymentFilter = .all
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    
    let patientId: UUID
    
    enum PaymentFilter: String, CaseIterable {
        case all = "Todos"
        case succeeded = "Pagos"
        case pending = "Pendentes"
        case failed = "Falharam"
        case refunded = "Reembolsados"
        
        var status: PaymentStatus? {
            switch self {
            case .all: return nil
            case .succeeded: return .succeeded
            case .pending: return .pending
            case .failed: return .failed
            case .refunded: return .refunded
            }
        }
    }
    
    var filteredPayments: [PatientPayment] {
        var filtered = payments
        
        // Apply status filter
        if let status = selectedFilter.status {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { payment in
                payment.description.localizedCaseInsensitiveContains(searchText) ||
                payment.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                payment.formattedAmount.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Payment List
                if filteredPayments.isEmpty {
                    emptyStateView
                } else {
                    paymentsList
                }
            }
            .navigationTitle("Histórico de Pagamentos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filtros") {
                        showingFilterSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheet
            }
            .refreshable {
                await loadPayments()
            }
        }
        .onAppear {
            Task {
                await loadPayments()
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
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
            .cornerRadius(8)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PaymentFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
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
    
    // MARK: - Payments List
    private var paymentsList: some View {
        List {
            ForEach(filteredPayments) { payment in
                PaymentHistoryRow(payment: payment)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Nenhum pagamento encontrado")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Não há pagamentos que correspondam aos filtros selecionados")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Limpar Filtros") {
                selectedFilter = .all
                searchText = ""
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Status do Pagamento")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(PaymentFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                HStack {
                                    if selectedFilter == filter {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(filter.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedFilter == filter ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        showingFilterSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        showingFilterSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadPayments() async {
        payments = await viewModel.loadPaymentHistory(for: patientId)
    }
}

// MARK: - Payment History Row
struct PaymentHistoryRow: View {
    let payment: PatientPayment
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status Icon
                Image(systemName: payment.statusIcon)
                    .font(.title2)
                    .foregroundColor(payment.status.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Description
                    Text(payment.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Date and Payment Method
                    HStack(spacing: 8) {
                        Text(payment.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: payment.paymentMethodType.icon)
                                .font(.caption)
                            Text(payment.paymentMethodType.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Status
                    Text(payment.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(payment.status.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Amount
                    Text(payment.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Overdue indicator
                    if payment.isOverdue {
                        Text("Vencido há \(payment.daysSinceDue) dias")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Filter Chip
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

// MARK: - Preview
struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView(patientId: UUID())
    }
}
