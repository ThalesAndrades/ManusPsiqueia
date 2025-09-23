//
//  IntegratedDiaryView.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Integrated diary view with advanced usability and AI insights
struct IntegratedDiaryView: View {
    @StateObject private var diaryManager = DiaryManager()
    @StateObject private var securityManager = DiarySecurityManager()
    @StateObject private var aiInsightsManager = DiaryAIInsightsManager()
    
    @State private var selectedTab: DiaryTab = .entries
    @State private var showingNewEntry = false
    @State private var showingPrivacyInfo = false
    @State private var showingInsights = false
    @State private var isUnlocked = false
    
    enum DiaryTab: String, CaseIterable {
        case entries = "Entradas"
        case insights = "Insights"
        case mood = "Humor"
        case settings = "Configurações"
        
        var icon: String {
            switch self {
            case .entries: return "book.fill"
            case .insights: return "brain.head.profile"
            case .mood: return "heart.fill"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        Group {
            if isUnlocked {
                DiaryMainContent()
            } else {
                DiaryLockScreen()
            }
        }
        .task {
            await securityManager.initializeSecurity()
        }
        .onChange(of: securityManager.isUnlocked) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                isUnlocked = newValue
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private func DiaryMainContent() -> some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with privacy indicator
                DiaryHeaderView()
                
                // Tab selector
                DiaryTabSelector()
                
                // Content based on selected tab
                TabContent()
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showingNewEntry) {
            NewDiaryEntryView(diaryManager: diaryManager)
        }
        .sheet(isPresented: $showingPrivacyInfo) {
            DiaryPrivacyInfoView()
        }
        .sheet(isPresented: $showingInsights) {
            DiaryInsightsView(aiInsightsManager: aiInsightsManager)
        }
    }
    
    // MARK: - Lock Screen
    
    @ViewBuilder
    private func DiaryLockScreen() -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Lock icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(securityManager.isLocked ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: securityManager.isLocked)
            
            VStack(spacing: 16) {
                Text("Diário Privado")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Seus pensamentos estão protegidos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if securityManager.isLocked {
                    if let lockoutEnd = securityManager.lockoutEndTime {
                        LockoutTimerView(endTime: lockoutEnd)
                    } else {
                        Text("Muitas tentativas falhadas")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            // Unlock button
            if !securityManager.isLocked {
                MentalHealthButton(
                    "Desbloquear Diário",
                    icon: securityManager.biometricType.icon,
                    style: .primary,
                    size: .large
                ) {
                    Task {
                        await authenticateUser()
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Privacy info button
            Button(action: { showingPrivacyInfo = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Informações de Privacidade")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func DiaryHeaderView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meu Diário")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("100% Privado")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Privacy info button
                Button(action: { showingPrivacyInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // Lock button
                Button(action: { Task { await securityManager.lockDiary() } }) {
                    Image(systemName: "lock")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // New entry button
                Button(action: { showingNewEntry = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selector
    
    @ViewBuilder
    private func DiaryTabSelector() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DiaryTab.allCases, id: \.self) { tab in
                    DiaryTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private func TabContent() -> some View {
        switch selectedTab {
        case .entries:
            DiaryEntriesListView(diaryManager: diaryManager)
        case .insights:
            DiaryInsightsTabView(aiInsightsManager: aiInsightsManager)
        case .mood:
            MoodTrackingView(diaryManager: diaryManager)
        case .settings:
            DiarySettingsView(securityManager: securityManager)
        }
    }
    
    // MARK: - Helper Methods
    
    private func authenticateUser() async {
        let success = await securityManager.authenticateUser()
        if success {
            withAnimation(.easeInOut(duration: 0.5)) {
                isUnlocked = true
            }
        }
    }
}

// MARK: - Supporting Views

struct DiaryTabButton: View {
    let tab: IntegratedDiaryView.DiaryTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [.blue, .purple],
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

struct LockoutTimerView: View {
    let endTime: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Conta temporariamente bloqueada")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
            
            Text("Tente novamente em \(timeString)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear {
            updateTimeRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, endTime.timeIntervalSinceNow)
        if timeRemaining <= 0 {
            timer?.invalidate()
        }
    }
}

// MARK: - Diary Entries List

struct DiaryEntriesListView: View {
    @ObservedObject var diaryManager: DiaryManager
    @State private var selectedEntry: DiaryEntry?
    @State private var searchText = ""
    
    var filteredEntries: [DiaryEntry] {
        if searchText.isEmpty {
            return diaryManager.entries
        } else {
            return diaryManager.entries.filter { entry in
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            AdvancedSearchBar(text: $searchText, placeholder: "Buscar no diário...")
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            
            if filteredEntries.isEmpty {
                EmptyDiaryView()
            } else {
                AdvancedScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEntries) { entry in
                            DiaryEntryCard(entry: entry) {
                                selectedEntry = entry
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            DiaryEntryDetailView(entry: entry, diaryManager: diaryManager)
        }
    }
}

struct DiaryEntryCard: View {
    let entry: DiaryEntry
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and mood
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    MoodIndicator(mood: entry.mood)
                }
                
                // Content preview
                Text(entry.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Tags and metrics
                HStack {
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if entry.hasAIInsights {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MoodIndicator: View {
    let mood: MoodState
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mood.color)
                .frame(width: 12, height: 12)
            
            Text(mood.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(mood.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(mood.color.opacity(0.1))
        )
    }
}

struct EmptyDiaryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Seu diário está vazio")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Comece escrevendo sobre seus pensamentos, sentimentos e experiências. Este é seu espaço privado e seguro.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

// MARK: - Diary Insights Tab

struct DiaryInsightsTabView: View {
    @ObservedObject var aiInsightsManager: DiaryAIInsightsManager
    @State private var selectedInsight: DiaryAIInsights?
    
    var body: some View {
        VStack(spacing: 16) {
            if aiInsightsManager.isGeneratingInsights {
                InsightsLoadingView()
            } else {
                InsightsContentView(
                    aiInsightsManager: aiInsightsManager,
                    selectedInsight: $selectedInsight
                )
            }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
}

struct InsightsLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Gerando insights...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InsightsContentView: View {
    @ObservedObject var aiInsightsManager: DiaryAIInsightsManager
    @Binding var selectedInsight: DiaryAIInsights?
    
    var body: some View {
        AdvancedScrollView {
            VStack(spacing: 20) {
                // Insights overview
                InsightsOverviewCard()
                
                // Recent insights
                InsightsListSection(
                    title: "Insights Recentes",
                    insights: [], // Would be populated from aiInsightsManager
                    onInsightTap: { insight in
                        selectedInsight = insight
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct InsightsOverviewCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights de IA")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Análise inteligente dos seus padrões")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                InsightMetric(title: "Humor", value: "Estável", color: .blue)
                InsightMetric(title: "Ansiedade", value: "Baixa", color: .green)
                InsightMetric(title: "Progresso", value: "Positivo", color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct InsightMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InsightsListSection: View {
    let title: String
    let insights: [DiaryAIInsights]
    let onInsightTap: (DiaryAIInsights) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if insights.isEmpty {
                EmptyInsightsView()
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight) {
                        onInsightTap(insight)
                    }
                }
            }
        }
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Nenhum insight disponível")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Escreva mais entradas no seu diário para gerar insights personalizados")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct InsightCard: View {
    let insight: DiaryAIInsights
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(insight.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    UrgencyIndicator(level: insight.riskAssessment.urgencyLevel)
                }
                
                Text("Análise de padrões comportamentais")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Tendência de humor: \(insight.moodAnalysis.trendDescription)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("Confiança: \(Int(insight.confidenceScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UrgencyIndicator: View {
    let level: UrgencyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.urgencyColor)
                .frame(width: 8, height: 8)
            
            Text(level.urgencyDescription.components(separatedBy: " - ").first ?? "")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(level.urgencyColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(level.urgencyColor.opacity(0.1))
        )
    }
}

// MARK: - Mood Tracking View

struct MoodTrackingView: View {
    @ObservedObject var diaryManager: DiaryManager
    
    var body: some View {
        AdvancedScrollView {
            VStack(spacing: 20) {
                MoodChartView(entries: diaryManager.entries)
                MoodStatsView(entries: diaryManager.entries)
                MoodPatternsView(entries: diaryManager.entries)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct MoodChartView: View {
    let entries: [DiaryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tendência de Humor")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Placeholder for mood chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Gráfico de Humor")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct MoodStatsView: View {
    let entries: [DiaryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estatísticas")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatCard(title: "Entradas", value: "\(entries.count)", color: .blue)
                StatCard(title: "Humor Médio", value: "7.2", color: .green)
                StatCard(title: "Sequência", value: "5 dias", color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct MoodPatternsView: View {
    let entries: [DiaryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Padrões Identificados")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PatternCard(
                    icon: "sun.max.fill",
                    title: "Humor matinal",
                    description: "Você tende a se sentir melhor pela manhã",
                    color: .yellow
                )
                
                PatternCard(
                    icon: "moon.fill",
                    title: "Reflexão noturna",
                    description: "Suas entradas mais profundas são à noite",
                    color: .indigo
                )
                
                PatternCard(
                    icon: "heart.fill",
                    title: "Estabilidade emocional",
                    description: "Seu humor tem se mantido estável",
                    color: .pink
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct PatternCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Diary Settings View

struct DiarySettingsView: View {
    @ObservedObject var securityManager: DiarySecurityManager
    @State private var showingSecurityReport = false
    @State private var showingDataExport = false
    
    var body: some View {
        AdvancedScrollView {
            VStack(spacing: 20) {
                SecuritySettingsSection(securityManager: securityManager)
                PrivacySettingsSection()
                DataManagementSection()
                SupportSection()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingSecurityReport) {
            SecurityReportView(securityManager: securityManager)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
    }
}

struct SecuritySettingsSection: View {
    @ObservedObject var securityManager: DiarySecurityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Segurança")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "shield.checkered",
                    title: "Nível de Segurança",
                    value: securityManager.securityLevel.displayName,
                    color: .green
                ) {
                    // Open security level selector
                }
                
                SettingsRow(
                    icon: securityManager.biometricType.icon,
                    title: "Autenticação",
                    value: securityManager.biometricType.displayName,
                    color: .blue
                ) {
                    // Open biometric settings
                }
                
                SettingsRow(
                    icon: "doc.text.magnifyingglass",
                    title: "Relatório de Segurança",
                    value: "Ver detalhes",
                    color: .purple
                ) {
                    // Show security report
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct PrivacySettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacidade")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingsToggle(
                    icon: "brain.head.profile",
                    title: "Análise de IA",
                    description: "Permitir insights inteligentes",
                    isOn: .constant(true),
                    color: .purple
                )
                
                SettingsToggle(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Analytics Anônimos",
                    description: "Ajudar a melhorar o app",
                    isOn: .constant(false),
                    color: .orange
                )
                
                SettingsRow(
                    icon: "info.circle",
                    title: "Política de Privacidade",
                    value: "Ler",
                    color: .blue
                ) {
                    // Open privacy policy
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct DataManagementSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gestão de Dados")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Exportar Dados",
                    value: "Baixar",
                    color: .blue
                ) {
                    // Export data
                }
                
                SettingsRow(
                    icon: "icloud.and.arrow.up",
                    title: "Backup",
                    value: "Configurar",
                    color: .green
                ) {
                    // Configure backup
                }
                
                SettingsRow(
                    icon: "trash",
                    title: "Deletar Todos os Dados",
                    value: "Cuidado",
                    color: .red
                ) {
                    // Delete all data
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct SupportSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suporte")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "Central de Ajuda",
                    value: "Abrir",
                    color: .blue
                ) {
                    // Open help center
                }
                
                SettingsRow(
                    icon: "envelope",
                    title: "Contato",
                    value: "contato@ailun.com.br",
                    color: .green
                ) {
                    // Open contact
                }
                
                SettingsRow(
                    icon: "info",
                    title: "Sobre",
                    value: "Versão 1.0.0",
                    color: .secondary
                ) {
                    // Show about
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if !value.isEmpty {
                        Text(value)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Additional Views

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Exportar Dados do Diário")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Seus dados serão exportados em formato seguro e legível")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                MentalHealthButton(
                    "Exportar Agora",
                    icon: "square.and.arrow.up",
                    style: .primary,
                    size: .large
                ) {
                    // Export data
                    dismiss()
                }
            }
            .padding(32)
            .navigationTitle("Exportar Dados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IntegratedDiaryView()
}
