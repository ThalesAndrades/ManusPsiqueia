//
//  AdvancedInputFields.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Advanced text field for mental health data input
struct MentalHealthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let validation: ((String) -> Bool)?
    let helpText: String?
    
    @State private var isEditing = false
    @State private var isValid = true
    @State private var showPassword = false
    @FocusState private var isFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        validation: ((String) -> Bool)? = nil,
        helpText: String? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.validation = validation
        self.helpText = helpText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .headerAccessibility(label: title)
            
            // Input field
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isFocused ? .purple : .secondary)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                            .mentalHealthAccessibility(
                                label: "\(title). Campo de senha segura.",
                                hint: "Insira sua senha. Suas informações são protegidas.",
                                value: text.isEmpty ? "Vazio" : "Preenchido",
                                traits: AccessibilityUtils.A11yTraits.secureField
                            )
                    } else {
                        TextField(placeholder, text: $text)
                            .mentalHealthAccessibility(
                                label: "\(title). \(placeholder)",
                                hint: helpText ?? "Campo de texto obrigatório",
                                value: text.isEmpty ? "Vazio" : text,
                                traits: AccessibilityUtils.A11yTraits.textField
                            )
                    }
                }
                .font(.body)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    validateInput(newValue)
                    if !isValid {
                        AccessibilityUtils.announceStateChange("Erro de validação no campo \(title)")
                    }
                }
                
                if isSecure {
                    Button(action: { 
                        showPassword.toggle() 
                        AccessibilityUtils.announceStateChange(showPassword ? "Senha visível" : "Senha oculta")
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonAccessibility(
                        label: showPassword ? "Ocultar senha" : "Mostrar senha",
                        hint: "Toque para alternar a visibilidade da senha"
                    )
                }
                
                if !isValid {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .accessibilityLabel("Erro de validação")
                        .accessibilityHint("Este campo contém um erro que precisa ser corrigido")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused
                                ? (isValid ? Color.purple : Color.red)
                                : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: isValid)
            
            // Help text or validation message
            if let helpText = helpText, isValid {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Texto de ajuda: \(helpText)")
                    .accessibilityTraits(.staticText)
            } else if !isValid {
                Text("Por favor, verifique o formato inserido")
                    .font(.caption)
                    .foregroundColor(.red)
                    .accessibilityLabel("Erro de validação: Por favor, verifique o formato inserido")
                    .accessibilityTraits(.staticText)
            }
        }
        .onAppear {
            validateInput(text)
        }
    }
    
    private func validateInput(_ input: String) {
        if let validation = validation {
            isValid = validation(input)
        } else {
            isValid = true
        }
    }
}

/// Advanced text editor for diary entries and longer texts
struct MentalHealthTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let characterLimit: Int?
    let showWordCount: Bool
    
    @State private var textHeight: CGFloat = 100
    @FocusState private var isFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 300,
        characterLimit: Int? = nil,
        showWordCount: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.characterLimit = characterLimit
        self.showWordCount = showWordCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and character count
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .headerAccessibility(label: title)
                
                Spacer()
                
                if showWordCount {
                    Text("\(text.count)\(characterLimit.map { "/\($0)" } ?? "") caracteres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(AccessibilityUtils.dynamicLabel(for: "text_count", value: text.count))
                        .accessibilityTraits(.updatesFrequently)
                }
            }
            
            // Text editor
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.purple : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(height: max(minHeight, min(maxHeight, textHeight)))
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .mentalHealthAccessibility(
                        label: "\(title). Editor de texto.",
                        hint: AccessibilityUtils.AccessibilityHints.diaryPrivacy,
                        value: text.isEmpty ? "Vazio" : "\(text.count) caracteres de texto",
                        traits: AccessibilityUtils.A11yTraits.textField
                    )
                    .onChange(of: text) { newValue in
                        if let limit = characterLimit, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                            AccessibilityUtils.announceStateChange("Limite de caracteres atingido")
                        }
                        updateTextHeight()
                    }
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: textHeight)
        }
        .onAppear {
            updateTextHeight()
        }
    }
    
    private func updateTextHeight() {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let textSize = text.boundingRect(
            with: CGSize(width: UIScreen.main.bounds.width - 64, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        textHeight = max(minHeight, min(maxHeight, textSize.height + 40))
    }
}

/// Mood scale slider for emotional intensity
struct MoodScaleSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let labels: [String]
    
    @State private var isDragging = false
    
    init(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 1...10,
        step: Double = 1,
        labels: [String] = ["Muito Baixo", "Baixo", "Médio", "Alto", "Muito Alto"]
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.labels = labels
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and current value
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .headerAccessibility(label: title)
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .frame(width: 30)
                    .accessibilityLabel("Valor atual: \(Int(value))")
                    .accessibilityTraits(.updatesFrequently)
            }
            
            // Custom slider
            VStack(spacing: 12) {
                // Slider track
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        // Active track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)),
                                height: 8
                            )
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                            .scaleEffect(isDragging ? 1.2 : 1.0)
                            .offset(
                                x: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 12
                            )
                            .sliderAccessibility(
                                label: "\(title). Escala de 1 a 10",
                                value: value,
                                range: range,
                                hint: "Deslize para ajustar o valor entre \(Int(range.lowerBound)) e \(Int(range.upperBound))"
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        isDragging = true
                                        let percent = min(max(0, gesture.location.x / geometry.size.width), 1)
                                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percent)
                                        let roundedValue = round(newValue / step) * step
                                        if abs(roundedValue - value) >= step {
                                            value = roundedValue
                                            // Provide haptic feedback for accessibility
                                            if AccessibilityConfiguration.shouldEnhanceHaptics {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        AccessibilityUtils.announceStateChange("\(title) definido para \(Int(value))")
                                    }
                            )
                    }
                }
                .frame(height: 24)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                
                // Labels
                HStack {
                    ForEach(labels.indices, id: \.self) { index in
                        Text(labels[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Nível \(index + 1): \(labels[index])")
                            .decorativeAccessibility()
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Escala de avaliação de \(labels.first ?? "Muito Baixo") a \(labels.last ?? "Muito Alto")")
            }
        }
    }
    
    private var gradientColors: [Color] {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        
        if normalizedValue < 0.3 {
            return [.blue, .cyan]
        } else if normalizedValue < 0.7 {
            return [.green, .yellow]
        } else {
            return [.orange, .red]
        }
    }
}

/// Tag input field for categorizing entries
struct TagInputField: View {
    let title: String
    @Binding var tags: [String]
    @State private var currentTag = ""
    @FocusState private var isFocused: Bool
    
    let suggestedTags = [
        "Ansiedade", "Depressão", "Estresse", "Trabalho", "Família",
        "Relacionamentos", "Sono", "Exercício", "Medicação", "Terapia",
        "Humor", "Energia", "Concentração", "Autoestima", "Gratidão"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .headerAccessibility(label: title)
            
            // Current tags
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag) {
                            tags.removeAll { $0 == tag }
                            AccessibilityUtils.announceStateChange("Tag \(tag) removida")
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(tags.count) tags selecionadas: \(tags.joined(separator: ", "))")
            }
            
            // Input field
            HStack {
                TextField("Adicionar tag...", text: $currentTag)
                    .font(.body)
                    .focused($isFocused)
                    .mentalHealthAccessibility(
                        label: "Campo de adição de tags",
                        hint: "Digite uma palavra-chave para categorizar esta entrada",
                        value: currentTag.isEmpty ? "Vazio" : currentTag,
                        traits: AccessibilityUtils.A11yTraits.textField
                    )
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
                .buttonAccessibility(
                    label: "Adicionar tag",
                    hint: "Toque para adicionar a tag digitada"
                )
                .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.purple : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            
            // Suggested tags
            if isFocused && !suggestedTags.isEmpty {
                Text("Sugestões:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Tags sugeridas")
                    .accessibilityTraits(.header)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(suggestedTags.filter { !tags.contains($0) }, id: \.self) { tag in
                        Button(action: {
                            tags.append(tag)
                            AccessibilityUtils.announceStateChange("Tag \(tag) adicionada")
                        }) {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                        .buttonAccessibility(
                            label: "Adicionar tag \(tag)",
                            hint: "Toque para adicionar esta tag sugerida"
                        )
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tags sugeridas disponíveis")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private func addTag() {
        let trimmedTag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            currentTag = ""
            AccessibilityUtils.announceStateChange("Tag \(trimmedTag) adicionada")
        } else if tags.contains(trimmedTag) {
            AccessibilityUtils.announceStateChange("Tag \(trimmedTag) já existe")
        }
    }
}

/// Individual tag view with remove functionality
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .accessibilityLabel("Tag: \(tag)")
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonAccessibility(
                label: "Remover tag \(tag)",
                hint: "Toque para remover esta tag"
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.1))
        .foregroundColor(.purple)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tag \(tag) removível")
        .accessibilityHint("Toque no X para remover")
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            MentalHealthTextField(
                "Email",
                text: .constant(""),
                placeholder: "seu@email.com",
                icon: "envelope",
                keyboardType: .emailAddress,
                validation: { $0.contains("@") },
                helpText: "Digite seu email para acesso"
            )
            
            MentalHealthTextEditor(
                "Como você está se sentindo hoje?",
                text: .constant(""),
                placeholder: "Descreva seus sentimentos, pensamentos e experiências...",
                minHeight: 120,
                characterLimit: 500,
                showWordCount: true
            )
            
            MoodScaleSlider(
                "Nível de Ansiedade",
                value: .constant(5.0)
            )
            
            TagInputField(
                "Tags",
                tags: .constant(["Ansiedade", "Trabalho"])
            )
        }
        .padding()
    }
}
