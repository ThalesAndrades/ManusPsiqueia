//
//  NewDiaryEntryView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct NewDiaryEntryView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: MoodState = .neutral
    @State private var anxietyLevel: Double = 5.0
    @State private var energyLevel: Double = 5.0
    @State private var sleepQuality: Double = 5.0
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var gratitudeItems: [String] = []
    @State private var newGratitude = ""
    
    @State private var isLoading = false
    @State private var showSaveConfirmation = false
    @State private var currentSection: EntrySection = .content
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, content, newTag, newGratitude
    }
    
    enum EntrySection: String, CaseIterable {
        case content = "Conteúdo"
        case mood = "Humor"
        case levels = "Níveis"
        case tags = "Tags"
        case gratitude = "Gratidão"
        
        var icon: String {
            switch self {
            case .content: return "text.quote"
            case .mood: return "face.smiling"
            case .levels: return "slider.horizontal.3"
            case .tags: return "tag"
            case .gratitude: return "heart"
            }
        }
    }
    
    var body: some View {
        AppleStyleNavigationView(
            title: "Nova Entrada",
            showBackButton: true,
            onBack: handleBackAction
        ) {
            VStack(spacing: 0) {
                // Section selector
                sectionSelector
                
                // Content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        switch currentSection {
                        case .content:
                            contentSection
                        case .mood:
                            moodSection
                        case .levels:
                            levelsSection
                        case .tags:
                            tagsSection
                        case .gratitude:
                            gratitudeSection
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
                
                // Save button
                saveButton
            }
        }
        .confirmationDialog("Descartar entrada?", isPresented: $showSaveConfirmation) {
            Button("Descartar", role: .destructive) {
                dismiss()
            }
            Button("Continuar editando", role: .cancel) { }
        } message: {
            Text("Você tem certeza que deseja descartar esta entrada? Todas as alterações serão perdidas.")
        }
    }
    
    private var sectionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(EntrySection.allCases, id: \.self) { section in
                    SectionPill(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: currentSection == section,
                        hasContent: sectionHasContent(section)
                    ) {
                        withAnimation(DesignSystem.Animation.spring) {
                            currentSection = section
                            focusedField = nil
                        }
                        DesignSystem.Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
    }
    
    private var contentSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Title field
            AppleStyleTextField(
                title: "Título (opcional)",
                text: $title,
                placeholder: "Como foi seu dia?",
                accessibilityHint: "Digite um título para sua entrada"
            )
            .focused($focusedField, equals: .title)
            
            // Content field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Como você se sente?")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.label)
                    .fontWeight(.medium)
                
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Escreva sobre seus pensamentos, sentimentos, ou como foi seu dia...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                            .padding(DesignSystem.Spacing.sm)
                    }
                    
                    TextEditor(text: $content)
                        .font(DesignSystem.Typography.body)
                        .padding(DesignSystem.Spacing.sm)
                        .focused($focusedField, equals: .content)
                        .scrollContentBackground(.hidden)
                }
                .frame(minHeight: 150)
                .background(DesignSystem.Colors.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(
                            focusedField == .content ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                            lineWidth: focusedField == .content ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                
                // Word count
                HStack {
                    Spacer()
                    Text("\(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) palavras")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
            }
        }
    }
    
    private var moodSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Como você está se sentindo?")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.label)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.md) {
                    ForEach(MoodState.allCases, id: \.self) { mood in
                        MoodCard(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            selectedMood = mood
                            DesignSystem.Haptics.selection()
                        }
                    }
                }
            }
            
            // Current mood display
            if selectedMood != .neutral {
                AppleStyleCard {
                    HStack {
                        Text(selectedMood.emoji)
                            .font(.title)
                        
                        VStack(alignment: .leading) {
                            Text("Humor selecionado:")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            
                            Text(selectedMood.name)
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedMood.color)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var levelsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Anxiety level
            LevelSlider(
                title: "Nível de Ansiedade",
                value: $anxietyLevel,
                range: 1...10,
                color: DesignSystem.Colors.warning,
                lowLabel: "Calmo",
                highLabel: "Ansioso"
            )
            
            // Energy level
            LevelSlider(
                title: "Nível de Energia",
                value: $energyLevel,
                range: 1...10,
                color: DesignSystem.Colors.success,
                lowLabel: "Cansado",
                highLabel: "Energético"
            )
            
            // Sleep quality
            LevelSlider(
                title: "Qualidade do Sono",
                value: $sleepQuality,
                range: 1...10,
                color: DesignSystem.Colors.info,
                lowLabel: "Ruim",
                highLabel: "Excelente"
            )
        }
    }
    
    private var tagsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Add new tag
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Adicionar Tags")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.label)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Ex: trabalho, família, exercício", text: $newTag)
                        .font(DesignSystem.Typography.body)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .newTag)
                        .onSubmit {
                            addTag()
                        }
                    
                    Button(action: addTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .disabled(newTag.isEmpty)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(
                            focusedField == .newTag ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                            lineWidth: focusedField == .newTag ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
            
            // Tags display
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Tags selecionadas:")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                removeTag(tag)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var gratitudeSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Add gratitude item
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Pelo que você é grato hoje?")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.label)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Ex: família, saúde, trabalho", text: $newGratitude)
                        .font(DesignSystem.Typography.body)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .newGratitude)
                        .onSubmit {
                            addGratitude()
                        }
                    
                    Button(action: addGratitude) {
                        Image(systemName: "heart.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .disabled(newGratitude.isEmpty)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(
                            focusedField == .newGratitude ? DesignSystem.Colors.primary : DesignSystem.Colors.separator,
                            lineWidth: focusedField == .newGratitude ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            }
            
            // Gratitude items
            if !gratitudeItems.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Lista de gratidão:")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    
                    ForEach(gratitudeItems, id: \.self) { item in
                        GratitudeItem(text: item) {
                            removeGratitude(item)
                        }
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Button(action: {
                    showSaveConfirmation = true
                }) {
                    Text("Cancelar")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: saveEntry) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Salvar Entrada")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isEntryValid || isLoading)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Helper Methods
    private func sectionHasContent(_ section: EntrySection) -> Bool {
        switch section {
        case .content:
            return !title.isEmpty || !content.isEmpty
        case .mood:
            return selectedMood != .neutral
        case .levels:
            return anxietyLevel != 5.0 || energyLevel != 5.0 || sleepQuality != 5.0
        case .tags:
            return !tags.isEmpty
        case .gratitude:
            return !gratitudeItems.isEmpty
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }
        
        tags.append(trimmedTag)
        newTag = ""
        DesignSystem.Haptics.success()
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        DesignSystem.Haptics.light()
    }
    
    private func addGratitude() {
        let trimmedGratitude = newGratitude.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGratitude.isEmpty && !gratitudeItems.contains(trimmedGratitude) else { return }
        
        gratitudeItems.append(trimmedGratitude)
        newGratitude = ""
        DesignSystem.Haptics.success()
    }
    
    private func removeGratitude(_ item: String) {
        gratitudeItems.removeAll { $0 == item }
        DesignSystem.Haptics.light()
    }
    
    private var isEntryValid: Bool {
        return !content.isEmpty
    }
    
    private func handleBackAction() {
        if hasUnsavedChanges {
            showSaveConfirmation = true
        } else {
            dismiss()
        }
    }
    
    private var hasUnsavedChanges: Bool {
        return !title.isEmpty || !content.isEmpty || selectedMood != .neutral ||
               anxietyLevel != 5.0 || energyLevel != 5.0 || sleepQuality != 5.0 ||
               !tags.isEmpty || !gratitudeItems.isEmpty
    }
    
    private func saveEntry() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        focusedField = nil
        
        // Create diary entry
        var diaryEntry = DiaryEntry(
            patientId: userId,
            content: content,
            mood: selectedMood,
            anxietyLevel: anxietyLevel,
            energyLevel: energyLevel
        )
        
        diaryEntry.title = title.isEmpty ? nil : title
        diaryEntry.sleepQuality = sleepQuality
        diaryEntry.tags = tags
        diaryEntry.gratitude = gratitudeItems
        
        // Save entry (placeholder - would integrate with DiaryManager)
        Task {
            // Simulate API call
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                isLoading = false
                DesignSystem.Haptics.success()
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Components

struct SectionPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let hasContent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                
                if hasContent {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 6, height: 6)
                }
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

struct MoodCard: View {
    let mood: MoodState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(mood.emoji)
                    .font(.title2)
                
                Text(mood.name)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ?
                    mood.color.opacity(0.2) :
                    DesignSystem.Colors.tertiaryBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        isSelected ? mood.color : DesignSystem.Colors.separator,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

struct LevelSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let lowLabel: String
    let highLabel: String
    
    var body: some View {
        AppleStyleCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.label)
                    
                    Spacer()
                    
                    Text("\(Int(value))/10")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Slider(value: $value, in: range, step: 1) {
                        Text(title)
                    }
                    .accentColor(color)
                    .onChange(of: value) { _ in
                        DesignSystem.Haptics.selection()
                    }
                    
                    HStack {
                        Text(lowLabel)
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        
                        Spacer()
                        
                        Text(highLabel)
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                }
            }
        }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Text(tag)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(DesignSystem.Colors.primary.opacity(0.1))
        .foregroundColor(DesignSystem.Colors.primary)
        .clipShape(Capsule())
    }
}

struct GratitudeItem: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "heart.fill")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.accent)
            
            Text(text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.label)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }
}

#Preview {
    NewDiaryEntryView()
        .environmentObject(AuthenticationManager())
        .environmentObject(NavigationManager.shared)
}