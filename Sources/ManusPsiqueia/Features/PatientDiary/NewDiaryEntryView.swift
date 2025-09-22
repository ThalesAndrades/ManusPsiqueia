//
//  NewDiaryEntryView.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Advanced diary entry creation view with enhanced UX
struct NewDiaryEntryView: View {
    @ObservedObject var diaryManager: DiaryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var content = ""
    @State private var selectedMood: MoodState = .neutral
    @State private var anxietyLevel: Double = 5.0
    @State private var energyLevel: Double = 5.0
    @State private var sleepQuality: Double = 5.0
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var triggers: [String] = []
    @State private var copingStrategies: [String] = []
    @State private var symptoms: [DiarySymptom] = []
    
    @State private var showingMoodSelector = false
    @State private var showingTagSuggestions = false
    @State private var showingSymptomSelector = false
    @State private var isSaving = false
    @State private var showingSaveConfirmation = false
    
    @FocusState private var isContentFocused: Bool
    @FocusState private var isTagFieldFocused: Bool
    
    private let maxContentLength = 5000
    private let suggestedTags = [
        "trabalho", "família", "relacionamento", "ansiedade", "estresse",
        "sono", "exercício", "medicação", "terapia", "autoestima",
        "futuro", "passado", "medo", "raiva", "tristeza", "alegria",
        "esperança", "solidão", "culpa", "gratidão"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with privacy reminder
                PrivacyReminderHeader()
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Content input
                        ContentInputSection()
                        
                        // Mood and metrics
                        MoodMetricsSection()
                        
                        // Tags section
                        TagsSection()
                        
                        // Additional details
                        AdditionalDetailsSection()
                        
                        // Save button
                        SaveButtonSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Nova Entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salvar") {
                        saveEntry()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
        .sheet(isPresented: $showingMoodSelector) {
            MoodSelectorView(selectedMood: $selectedMood)
        }
        .sheet(isPresented: $showingSymptomSelector) {
            SymptomSelectorView(selectedSymptoms: $symptoms)
        }
        .alert("Entrada Salva", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Sua entrada foi salva com segurança no seu diário privado.")
        }
    }
    
    // MARK: - Privacy Reminder Header
    
    @ViewBuilder
    private func PrivacyReminderHeader() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Espaço 100% Privado")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text("Apenas você tem acesso a estas informações")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.05))
    }
    
    // MARK: - Content Input Section
    
    @ViewBuilder
    private func ContentInputSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Como você está se sentindo?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(content.count)/\(maxContentLength)")
                    .font(.caption)
                    .foregroundColor(content.count > maxContentLength * 9/10 ? .red : .secondary)
            }
            
            AdvancedTextEditor(
                text: $content,
                placeholder: "Escreva sobre seus pensamentos, sentimentos, experiências do dia, ou qualquer coisa que queira registrar...",
                maxLength: maxContentLength
            )
            .focused($isContentFocused)
            .frame(minHeight: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Mood and Metrics Section
    
    @ViewBuilder
    private func MoodMetricsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Como você se sente agora?")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Mood selector
            Button(action: { showingMoodSelector = true }) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(selectedMood.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(selectedMood.emoji)
                                .font(.system(size: 16))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Humor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(selectedMood.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Metrics sliders
            VStack(spacing: 16) {
                MetricSlider(
                    title: "Nível de Ansiedade",
                    value: $anxietyLevel,
                    range: 0...10,
                    color: .orange,
                    lowLabel: "Calmo",
                    highLabel: "Ansioso"
                )
                
                MetricSlider(
                    title: "Nível de Energia",
                    value: $energyLevel,
                    range: 0...10,
                    color: .yellow,
                    lowLabel: "Cansado",
                    highLabel: "Energético"
                )
                
                MetricSlider(
                    title: "Qualidade do Sono",
                    value: $sleepQuality,
                    range: 0...10,
                    color: .indigo,
                    lowLabel: "Ruim",
                    highLabel: "Excelente"
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
    
    // MARK: - Tags Section
    
    @ViewBuilder
    private func TagsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Temas e Palavras-chave")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Current tags
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(
                            text: tag,
                            color: .blue,
                            onRemove: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        )
                    }
                }
            }
            
            // Add new tag
            HStack(spacing: 12) {
                AdvancedTextField(
                    text: $newTag,
                    placeholder: "Adicionar tema...",
                    style: .rounded
                )
                .focused($isTagFieldFocused)
                .onSubmit {
                    addTag()
                }
                
                MentalHealthButton(
                    "Adicionar",
                    icon: "plus",
                    style: .secondary,
                    size: .small
                ) {
                    addTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Suggested tags
            if !suggestedTags.isEmpty && isTagFieldFocused {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sugestões")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(suggestedTags.filter { !tags.contains($0) }.prefix(10), id: \.self) { tag in
                            Button(action: { addSuggestedTag(tag) }) {
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
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
    
    // MARK: - Additional Details Section
    
    @ViewBuilder
    private func AdditionalDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detalhes Adicionais")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Triggers
                ExpandableSection(
                    title: "Gatilhos",
                    icon: "exclamationmark.triangle",
                    color: .orange,
                    items: $triggers,
                    placeholder: "O que desencadeou estes sentimentos?"
                )
                
                // Coping strategies
                ExpandableSection(
                    title: "Estratégias de Enfrentamento",
                    icon: "shield.checkered",
                    color: .green,
                    items: $copingStrategies,
                    placeholder: "Como você lidou com a situação?"
                )
                
                // Symptoms
                Button(action: { showingSymptomSelector = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sintomas")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(symptoms.isEmpty ? "Nenhum sintoma selecionado" : "\(symptoms.count) sintoma(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Save Button Section
    
    @ViewBuilder
    private func SaveButtonSection() -> some View {
        VStack(spacing: 16) {
            MentalHealthButton(
                isSaving ? "Salvando..." : "Salvar Entrada",
                icon: isSaving ? "arrow.clockwise" : "checkmark.circle.fill",
                style: .primary,
                size: .large
            ) {
                saveEntry()
            }
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            
            Text("Sua entrada será criptografada e armazenada com segurança")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedTag.isEmpty,
              !tags.contains(trimmedTag),
              tags.count < 10 else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func addSuggestedTag(_ tag: String) {
        guard !tags.contains(tag), tags.count < 10 else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            tags.append(tag)
        }
    }
    
    private func saveEntry() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        
        let entry = DiaryEntry(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: selectedMood,
            anxietyLevel: anxietyLevel,
            energyLevel: energyLevel,
            sleepQuality: sleepQuality,
            tags: tags,
            triggers: triggers,
            copingStrategies: copingStrategies,
            symptoms: symptoms
        )
        
        Task {
            do {
                try await diaryManager.saveEntry(entry)
                
                await MainActor.run {
                    isSaving = false
                    showingSaveConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // Handle error
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let lowLabel: String
    let highLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(format: "%.0f", value))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.1))
                    )
            }
            
            Slider(value: $value, in: range, step: 1.0)
                .tint(color)
            
            HStack {
                Text(lowLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(highLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ExpandableSection: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var items: [String]
    let placeholder: String
    
    @State private var isExpanded = false
    @State private var newItem = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(items.isEmpty ? "Nenhum item" : "\(items.count) item(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    // Current items
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    items.removeAll { $0 == item }
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Add new item
                    HStack(spacing: 8) {
                        AdvancedTextField(
                            text: $newItem,
                            placeholder: placeholder,
                            style: .rounded
                        )
                        .onSubmit {
                            addItem()
                        }
                        
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(color)
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedItem.isEmpty,
              !items.contains(trimmedItem),
              items.count < 5 else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(trimmedItem)
            newItem = ""
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index] + bounds.origin, proposal: .unspecified)
        }
    }
}

struct FlowResult {
    let size: CGSize
    let positions: [CGPoint]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var positions: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxY: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + subviewSize.width > maxWidth && currentPosition.x > 0 {
                // Move to next line
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(currentPosition)
            currentPosition.x += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
            maxY = max(maxY, currentPosition.y + subviewSize.height)
        }
        
        self.positions = positions
        self.size = CGSize(width: maxWidth, height: maxY)
    }
}

// MARK: - Mood Selector View

struct MoodSelectorView: View {
    @Binding var selectedMood: MoodState
    @Environment(\.dismiss) private var dismiss
    
    private let moods: [MoodState] = [
        .veryHappy, .happy, .neutral, .sad, .verySad,
        .excited, .calm, .anxious, .angry, .grateful
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Como você está se sentindo?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(moods, id: \.self) { mood in
                        MoodOptionCard(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            selectedMood = mood
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Selecionar Humor")
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

struct MoodOptionCard: View {
    let mood: MoodState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(mood.emoji)
                    .font(.system(size: 48))
                
                Text(mood.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(mood.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mood.color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Symptom Selector View

struct SymptomSelectorView: View {
    @Binding var selectedSymptoms: [DiarySymptom]
    @Environment(\.dismiss) private var dismiss
    
    private let availableSymptoms: [DiarySymptom] = [
        DiarySymptom(symptom: "Dor de cabeça", severity: .mild),
        DiarySymptom(symptom: "Insônia", severity: .moderate),
        DiarySymptom(symptom: "Fadiga", severity: .mild),
        DiarySymptom(symptom: "Palpitações", severity: .moderate),
        DiarySymptom(symptom: "Tensão muscular", severity: .mild),
        DiarySymptom(symptom: "Dificuldade de concentração", severity: .moderate),
        DiarySymptom(symptom: "Irritabilidade", severity: .mild),
        DiarySymptom(symptom: "Perda de apetite", severity: .moderate),
        DiarySymptom(symptom: "Sudorese", severity: .mild),
        DiarySymptom(symptom: "Tremores", severity: .severe)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Selecione os sintomas que você está sentindo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                List {
                    ForEach(availableSymptoms, id: \.symptom) { symptom in
                        SymptomRow(
                            symptom: symptom,
                            isSelected: selectedSymptoms.contains { $0.symptom == symptom.symptom }
                        ) {
                            toggleSymptom(symptom)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Sintomas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluir") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleSymptom(_ symptom: DiarySymptom) {
        if let index = selectedSymptoms.firstIndex(where: { $0.symptom == symptom.symptom }) {
            selectedSymptoms.remove(at: index)
        } else {
            selectedSymptoms.append(symptom)
        }
    }
}

struct SymptomRow: View {
    let symptom: DiarySymptom
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(symptom.symptom)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Intensidade: \(symptom.severity.name)")
                        .font(.caption)
                        .foregroundColor(symptom.severity.color)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewDiaryEntryView(diaryManager: DiaryManager())
}
