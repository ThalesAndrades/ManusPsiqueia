//
//  PatientMainView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct PatientMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        TabView(selection: $navigationManager.currentTab) {
            // Diary Tab
            NavigationStack(path: $navigationManager.navigationPath) {
                DiaryMainView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationDestination(for: destination)
                    }
            }
            .tabItem {
                Label(
                    NavigationManager.TabDestination.diary.title,
                    systemImage: navigationManager.currentTab == .diary ? 
                        NavigationManager.TabDestination.diary.iconSelected :
                        NavigationManager.TabDestination.diary.icon
                )
            }
            .tag(NavigationManager.TabDestination.diary)
            .accessibilityLabel("Diário")
            .accessibilityHint("Acesse suas entradas de diário")
            
            // Insights Tab
            NavigationStack(path: $navigationManager.navigationPath) {
                InsightsMainView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationDestination(for: destination)
                    }
            }
            .tabItem {
                Label(
                    NavigationManager.TabDestination.insights.title,
                    systemImage: navigationManager.currentTab == .insights ?
                        NavigationManager.TabDestination.insights.iconSelected :
                        NavigationManager.TabDestination.insights.icon
                )
            }
            .tag(NavigationManager.TabDestination.insights)
            .accessibilityLabel("Insights")
            .accessibilityHint("Veja análises e padrões do seu diário")
            
            // Goals Tab
            NavigationStack(path: $navigationManager.navigationPath) {
                GoalsMainView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationDestination(for: destination)
                    }
            }
            .tabItem {
                Label(
                    NavigationManager.TabDestination.goals.title,
                    systemImage: navigationManager.currentTab == .goals ?
                        NavigationManager.TabDestination.goals.iconSelected :
                        NavigationManager.TabDestination.goals.icon
                )
            }
            .tag(NavigationManager.TabDestination.goals)
            .accessibilityLabel("Metas")
            .accessibilityHint("Gerencie suas metas pessoais")
            
            // Profile Tab
            NavigationStack(path: $navigationManager.navigationPath) {
                ProfileMainView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationDestination(for: destination)
                    }
            }
            .tabItem {
                Label(
                    NavigationManager.TabDestination.profile.title,
                    systemImage: navigationManager.currentTab == .profile ?
                        NavigationManager.TabDestination.profile.iconSelected :
                        NavigationManager.TabDestination.profile.icon
                )
            }
            .tag(NavigationManager.TabDestination.profile)
            .accessibilityLabel("Perfil")
            .accessibilityHint("Acesse e edite seu perfil")
        }
        .accentColor(DesignSystem.Colors.primary)
        .onChange(of: navigationManager.currentTab) { newTab in
            DesignSystem.Haptics.selection()
            navigationManager.announceNavigation(to: newTab.title)
        }
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    private func navigationDestination(for destination: NavigationDestination) -> some View {
        switch destination {
        case .newDiaryEntry:
            NewDiaryEntryView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .aiAnalysis(let entry):
            AIAnalysisView(diaryEntry: entry)
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .paywall:
            PaywallView()
                .environmentObject(subscriptionManager)
                .environmentObject(navigationManager)
        case .settings:
            SettingsView()
                .environmentObject(authManager)
                .environmentObject(navigationManager)
        case .help:
            HelpView()
                .environmentObject(navigationManager)
        case .privacyPolicy:
            PrivacyPolicyView()
                .environmentObject(navigationManager)
        case .termsOfService:
            TermsOfServiceView()
                .environmentObject(navigationManager)
        default:
            Text("Destination not implemented")
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
        }
    }
}

// MARK: - Diary Main View
struct DiaryMainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject private var diaryManager = DiaryManager()
    
    @State private var searchText = ""
    @State private var selectedMoodFilter: MoodFilter = .all
    @State private var showingFilters = false
    
    enum MoodFilter: String, CaseIterable {
        case all = "Todos"
        case happy = "Feliz"
        case neutral = "Neutro"
        case sad = "Triste"
        
        var icon: String {
            switch self {
            case .all: return "line.3.horizontal.decrease.circle"
            case .happy: return "face.smiling"
            case .neutral: return "face.dashed"
            case .sad: return "face.dashed"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            searchAndFilterBar
            
            // Content
            if diaryManager.isLoading {
                AppleLoadingView(message: "Carregando entradas...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredEntries.isEmpty {
                emptyStateView
            } else {
                entriesList
            }
        }
        .navigationTitle("Meu Diário")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    DesignSystem.Haptics.light()
                    navigationManager.presentSheet(.newDiaryEntry)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .accessibilityLabel("Nova entrada")
                .accessibilityHint("Crie uma nova entrada no diário")
            }
        }
        .onAppear {
            loadDiaryEntries()
        }
        .refreshable {
            await refreshDiaryEntries()
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                
                TextField("Buscar entradas...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        DesignSystem.Haptics.light()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(MoodFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedMoodFilter == filter
                        ) {
                            selectedMoodFilter = filter
                            DesignSystem.Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
    }
    
    private var entriesList: some View {
        List {
            ForEach(filteredEntries) { entry in
                DiaryEntryCard(entry: entry) {
                    // Handle entry tap
                    if subscriptionManager.hasActivePremiumSubscription {
                        navigationManager.navigate(to: .aiAnalysis(entry))
                    } else {
                        navigationManager.presentSheet(.paywall)
                    }
                }
                .listRowInsets(EdgeInsets(
                    top: DesignSystem.Spacing.xs,
                    leading: DesignSystem.Spacing.md,
                    bottom: DesignSystem.Spacing.xs,
                    trailing: DesignSystem.Spacing.md
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteDiaryEntries)
        }
        .listStyle(.plain)
        .background(DesignSystem.Colors.background)
    }
    
    private var emptyStateView: some View {
        AppleEmptyStateView(
            icon: "book.closed",
            title: searchText.isEmpty ? "Comece seu diário" : "Nenhuma entrada encontrada",
            description: searchText.isEmpty ? 
                "Suas primeiras palavras podem ser o começo de uma jornada incrível de autoconhecimento." :
                "Tente ajustar sua busca ou filtros para encontrar o que procura.",
            actionTitle: searchText.isEmpty ? "Criar primeira entrada" : nil
        ) {
            if searchText.isEmpty {
                navigationManager.presentSheet(.newDiaryEntry)
            }
        }
    }
    
    private var filteredEntries: [DiaryEntry] {
        diaryManager.entries
            .filter { entry in
                if !searchText.isEmpty {
                    let titleMatch = entry.title?.localizedCaseInsensitiveContains(searchText) ?? false
                    let contentMatch = entry.content.localizedCaseInsensitiveContains(searchText)
                    return titleMatch || contentMatch
                }
                return true
            }
            .filter { entry in
                switch selectedMoodFilter {
                case .all:
                    return true
                case .happy:
                    return entry.mood.intensity >= 7
                case .neutral:
                    return entry.mood.intensity >= 4 && entry.mood.intensity <= 6
                case .sad:
                    return entry.mood.intensity <= 3
                }
            }
    }
    
    private func loadDiaryEntries() {
        Task {
            await diaryManager.loadEntries()
        }
    }
    
    private func refreshDiaryEntries() async {
        await diaryManager.refreshEntries()
    }
    
    private func deleteDiaryEntries(offsets: IndexSet) {
        Task {
            for index in offsets {
                await diaryManager.deleteEntry(filteredEntries[index])
            }
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                isSelected ? 
                    DesignSystem.Colors.primary : 
                    DesignSystem.Colors.tertiaryBackground
            )
            .foregroundColor(
                isSelected ? 
                    .white : 
                    DesignSystem.Colors.label
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Diary Entry Card
struct DiaryEntryCard: View {
    let entry: DiaryEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppleStyleCard {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title ?? "Entrada sem título")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.label)
                                .lineLimit(1)
                            
                            Text(entry.timestamp, style: .relative)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                        
                        Spacer()
                        
                        // Mood indicator
                        MoodIndicator(mood: entry.mood)
                    }
                    
                    // Content preview
                    Text(entry.content)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Footer with AI analysis indicator
                    if entry.aiInsightsGenerated {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("Análise de IA disponível")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Entrada do diário: \(entry.title ?? "Sem título")")
        .accessibilityHint("Toque para ver detalhes ou análise de IA")
    }
}

// MARK: - Mood Indicator
struct MoodIndicator: View {
    let mood: MoodState
    
    var body: some View {
        HStack(spacing: 4) {
            Text(mood.emoji)
                .font(.caption)
            
            Text(mood.name)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(mood.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(mood.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    PatientMainView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(NavigationManager.shared)
}