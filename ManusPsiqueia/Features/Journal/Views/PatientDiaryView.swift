#if canImport(ManusPsiqueiaUI) && canImport(SwiftUI)
import ManusPsiqueiaUI
import SwiftUI
#endif

/// Main diary interface for patients with privacy-first design
struct PatientDiaryView: View {
    @StateObject private var diaryManager = DiaryManager()
    @State private var showingNewEntry = false
    @State private var showingPrivacyInfo = false
    @State private var selectedFilter: DiaryFilter = .all
    @State private var searchText = ""
    
    enum DiaryFilter: String, CaseIterable {
        case all = "Todas"
        case today = "Hoje"
        case week = "Esta Semana"
        case month = "Este Mês"
        case mood = "Por Humor"
        case tags = "Por Tags"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Privacy banner
                PrivacyBannerView(showingInfo: $showingPrivacyInfo)
                
                // Main content
                if diaryManager.entries.isEmpty {
                    EmptyDiaryView(showingNewEntry: $showingNewEntry)
                } else {
                    DiaryContentView(
                        entries: filteredEntries,
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        showingNewEntry: $showingNewEntry
                    )
                }
            }
            .navigationTitle("Meu Diário Privado")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingPrivacyInfo = true }) {
                        Image(systemName: "lock.shield")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewDiaryEntryView(diaryManager: diaryManager)
        }
        .sheet(isPresented: $showingPrivacyInfo) {
            DiaryPrivacyInfoView()
        }
        .onAppear {
            diaryManager.loadEntries()
        }
    }
    
    private var filteredEntries: [DiaryEntry] {
        var entries = diaryManager.entries
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .today:
            entries = entries.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            entries = entries.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            entries = entries.filter { $0.timestamp >= monthAgo }
        case .mood, .tags:
            break // Handled by separate filters
        }
        
        // Apply search
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.title?.localizedCaseInsensitiveContains(searchText) == true ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return DiaryEntry.sortedByDate(entries)
    }
}

/// Privacy banner emphasizing data protection
struct PrivacyBannerView: View {
    @Binding var showingInfo: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("100% Privado e Seguro")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Seus dados são criptografados e nunca compartilhados")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingInfo = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

/// Empty state view for new users
struct EmptyDiaryView: View {
    @Binding var showingNewEntry: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Bem-vindo ao seu Diário Privado")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Este é seu espaço seguro para registrar pensamentos, sentimentos e experiências. Tudo aqui é completamente privado e criptografado.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                MentalHealthButton(
                    "Criar Primeira Entrada",
                    icon: "plus.circle",
                    style: .primary,
                    size: .large
                ) {
                    showingNewEntry = true
                }
                
                MentalHealthButton(
                    "Explorar Templates",
                    icon: "doc.text",
                    style: .secondary,
                    size: .medium
                ) {
                    // Show templates
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Benefits list
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "lock.fill", text: "Totalmente privado e criptografado")
                BenefitRow(icon: "brain.head.profile", text: "IA gera insights para seu terapeuta")
                BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Acompanhe seu progresso ao longo do tempo")
                BenefitRow(icon: "heart.fill", text: "Melhore seu bem-estar mental")
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

/// Benefit row for empty state
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

/// Main content view with entries
struct DiaryContentView: View {
    let entries: [DiaryEntry]
    @Binding var searchText: String
    @Binding var selectedFilter: PatientDiaryView.DiaryFilter
    @Binding var showingNewEntry: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar entradas...", text: $searchText)
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PatientDiaryView.DiaryFilter.allCases, id: \.self) { filter in
                            FilterTab(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Entries list
            AdvancedScrollView(onRefresh: {
                // Refresh entries
            }) {
                LazyVStack(spacing: 16) {
                    ForEach(entries) { entry in
                        DiaryEntryCard(entry: entry)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

/// Filter tab component
struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
    }
}

/// Individual diary entry card
struct DiaryEntryCard: View {
    let entry: DiaryEntry
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with mood and date
                HStack {
                    HStack(spacing: 8) {
                        Text(entry.mood.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.mood.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if entry.aiInsightsGenerated {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
                
                // Content preview
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Text(entry.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .clipShape(Capsule())
                            }
                            
                            if entry.tags.count > 3 {
                                Text("+\(entry.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Footer with stats
                HStack {
                    Label("\(entry.wordCount) palavras", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(entry.readingTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            DiaryEntryDetailView(entry: entry)
        }
    }
}

#Preview {
    PatientDiaryView()
        .preferredColorScheme(.light)
}
