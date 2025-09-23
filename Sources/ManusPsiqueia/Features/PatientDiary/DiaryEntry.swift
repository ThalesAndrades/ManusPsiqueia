//
//  DiaryEntry.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

/// Model representing a private diary entry for mental health tracking
struct DiaryEntry: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let timestamp: Date
    var title: String?
    var content: String
    var mood: MoodState
    var anxietyLevel: Double
    var energyLevel: Double
    var sleepQuality: Double?
    var tags: [String]
    var emotions: [EmotionIntensity]
    var triggers: [String]
    var copingStrategies: [String]
    var gratitude: [String]
    var goals: [String]
    var medications: [MedicationEntry]?
    var symptoms: [SymptomEntry]
    var isPrivate: Bool
    var aiInsightsGenerated: Bool
    var lastModified: Date
    
    init(
        patientId: UUID,
        content: String = "",
        mood: MoodState = .neutral,
        anxietyLevel: Double = 5.0,
        energyLevel: Double = 5.0
    ) {
        self.id = UUID()
        self.patientId = patientId
        self.timestamp = Date()
        self.content = content
        self.mood = mood
        self.anxietyLevel = anxietyLevel
        self.energyLevel = energyLevel
        self.tags = []
        self.emotions = []
        self.triggers = []
        self.copingStrategies = []
        self.gratitude = []
        self.goals = []
        self.symptoms = []
        self.isPrivate = true // Always private by default
        self.aiInsightsGenerated = false
        self.lastModified = Date()
    }
}

/// Mood states for diary entries
enum MoodState: String, CaseIterable, Codable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case verySad = "very_sad"
    case anxious = "anxious"
    case angry = "angry"
    case calm = "calm"
    case excited = "excited"
    case tired = "tired"
    case overwhelmed = "overwhelmed"
    case hopeful = "hopeful"
    case frustrated = "frustrated"
    case peaceful = "peaceful"
    case confused = "confused"
    
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .verySad: return "😢"
        case .anxious: return "😰"
        case .angry: return "😠"
        case .calm: return "😌"
        case .excited: return "🤗"
        case .tired: return "😴"
        case .overwhelmed: return "😵‍💫"
        case .hopeful: return "🙂"
        case .frustrated: return "😤"
        case .peaceful: return "☺️"
        case .confused: return "😕"
        }
    }
    
    var name: String {
        switch self {
        case .veryHappy: return "Muito Feliz"
        case .happy: return "Feliz"
        case .neutral: return "Neutro"
        case .sad: return "Triste"
        case .verySad: return "Muito Triste"
        case .anxious: return "Ansioso"
        case .angry: return "Irritado"
        case .calm: return "Calmo"
        case .excited: return "Animado"
        case .tired: return "Cansado"
        case .overwhelmed: return "Sobrecarregado"
        case .hopeful: return "Esperançoso"
        case .frustrated: return "Frustrado"
        case .peaceful: return "Em Paz"
        case .confused: return "Confuso"
        }
    }
    
    var color: Color {
        switch self {
        case .veryHappy, .happy, .excited, .hopeful: return .green
        case .neutral, .calm, .peaceful: return .blue
        case .sad, .verySad, .tired: return .indigo
        case .anxious, .overwhelmed, .confused: return .orange
        case .angry, .frustrated: return .red
        }
    }
    
    var intensity: Double {
        switch self {
        case .veryHappy: return 9.0
        case .happy: return 7.0
        case .excited: return 8.0
        case .hopeful: return 6.0
        case .neutral: return 5.0
        case .calm: return 6.0
        case .peaceful: return 7.0
        case .tired: return 4.0
        case .confused: return 4.0
        case .sad: return 3.0
        case .frustrated: return 3.0
        case .anxious: return 2.0
        case .overwhelmed: return 2.0
        case .angry: return 2.0
        case .verySad: return 1.0
        }
    }
}

/// Emotion with intensity level
struct EmotionIntensity: Identifiable, Codable {
    let id: UUID
    let emotion: String
    let intensity: Double // 1-10 scale
    let timestamp: Date
    
    init(emotion: String, intensity: Double) {
        self.id = UUID()
        self.emotion = emotion
        self.intensity = intensity
        self.timestamp = Date()
    }
}

/// Medication tracking entry
struct MedicationEntry: Identifiable, Codable {
    let id: UUID
    let name: String
    let dosage: String
    let timeTaken: Date
    let effectiveness: Double? // 1-10 scale
    let sideEffects: [String]
    let notes: String?
    
    init(name: String, dosage: String, timeTaken: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.timeTaken = timeTaken
        self.effectiveness = nil
        self.sideEffects = []
        self.notes = nil
    }
}

/// Symptom tracking entry
struct SymptomEntry: Identifiable, Codable {
    let id: UUID
    let symptom: String
    let severity: Double // 1-10 scale
    let duration: String?
    let triggers: [String]
    let timestamp: Date
    
    init(symptom: String, severity: Double) {
        self.id = UUID()
        self.symptom = symptom
        self.severity = severity
        self.duration = nil
        self.triggers = []
        self.timestamp = Date()
    }
}

/// Diary entry template for guided journaling
struct DiaryTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let prompts: [JournalPrompt]
    let category: TemplateCategory
    let estimatedTime: Int // minutes
    let icon: String
    
    enum TemplateCategory: String, CaseIterable, Codable {
        case daily = "daily"
        case anxiety = "anxiety"
        case depression = "depression"
        case gratitude = "gratitude"
        case goals = "goals"
        case relationships = "relationships"
        case selfCare = "self_care"
        case therapy = "therapy"
        case medication = "medication"
        case sleep = "sleep"
        case work = "work"
        case family = "family"
        
        var name: String {
            switch self {
            case .daily: return "Diário Diário"
            case .anxiety: return "Ansiedade"
            case .depression: return "Depressão"
            case .gratitude: return "Gratidão"
            case .goals: return "Objetivos"
            case .relationships: return "Relacionamentos"
            case .selfCare: return "Autocuidado"
            case .therapy: return "Terapia"
            case .medication: return "Medicação"
            case .sleep: return "Sono"
            case .work: return "Trabalho"
            case .family: return "Família"
            }
        }
        
        var color: Color {
            switch self {
            case .daily: return .blue
            case .anxiety: return .orange
            case .depression: return .indigo
            case .gratitude: return .green
            case .goals: return .purple
            case .relationships: return .pink
            case .selfCare: return .mint
            case .therapy: return .teal
            case .medication: return .red
            case .sleep: return .indigo
            case .work: return .brown
            case .family: return .yellow
            }
        }
    }
}

/// Individual journal prompt
struct JournalPrompt: Identifiable, Codable {
    let id: UUID
    let question: String
    let type: PromptType
    let isRequired: Bool
    let helpText: String?
    
    enum PromptType: String, Codable {
        case text = "text"
        case scale = "scale"
        case multipleChoice = "multiple_choice"
        case tags = "tags"
        case mood = "mood"
        case time = "time"
        case number = "number"
    }
    
    init(question: String, type: PromptType, isRequired: Bool = false, helpText: String? = nil) {
        self.id = UUID()
        self.question = question
        self.type = type
        self.isRequired = isRequired
        self.helpText = helpText
    }
}

/// Diary statistics for insights
struct DiaryStatistics: Codable {
    let totalEntries: Int
    let averageMood: Double
    let averageAnxiety: Double
    let averageEnergy: Double
    let mostCommonTags: [String]
    let mostCommonTriggers: [String]
    let moodTrend: [MoodDataPoint]
    let anxietyTrend: [DataPoint]
    let energyTrend: [DataPoint]
    let entryFrequency: [DateFrequency]
    let longestStreak: Int
    let currentStreak: Int
    
    struct MoodDataPoint: Codable {
        let date: Date
        let mood: MoodState
        let intensity: Double
    }
    
    struct DataPoint: Codable {
        let date: Date
        let value: Double
    }
    
    struct DateFrequency: Codable {
        let date: Date
        let count: Int
    }
}

/// Privacy settings for diary
struct DiaryPrivacySettings: Codable {
    var isFullyPrivate: Bool
    var allowAIAnalysis: Bool
    var allowAnonymousResearch: Bool
    var shareWithTherapist: Bool
    var dataRetentionDays: Int
    var encryptionEnabled: Bool
    var biometricLockEnabled: Bool
    var autoDeleteAfterDays: Int?
    
    static let `default` = DiaryPrivacySettings(
        isFullyPrivate: true,
        allowAIAnalysis: true,
        allowAnonymousResearch: false,
        shareWithTherapist: false,
        dataRetentionDays: 365,
        encryptionEnabled: true,
        biometricLockEnabled: true,
        autoDeleteAfterDays: nil
    )
}

/// Extension for diary entry filtering and sorting
extension DiaryEntry {
    static func filterByDateRange(_ entries: [DiaryEntry], from startDate: Date, to endDate: Date) -> [DiaryEntry] {
        return entries.filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }
    
    static func filterByMood(_ entries: [DiaryEntry], moods: [MoodState]) -> [DiaryEntry] {
        return entries.filter { moods.contains($0.mood) }
    }
    
    static func filterByTags(_ entries: [DiaryEntry], tags: [String]) -> [DiaryEntry] {
        return entries.filter { entry in
            !Set(entry.tags).isDisjoint(with: Set(tags))
        }
    }
    
    static func sortedByDate(_ entries: [DiaryEntry], ascending: Bool = false) -> [DiaryEntry] {
        return entries.sorted { ascending ? $0.timestamp < $1.timestamp : $0.timestamp > $1.timestamp }
    }
    
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    var readingTime: Int {
        // Assuming 200 words per minute reading speed
        return max(1, wordCount / 200)
    }
}

/// Predefined diary templates
extension DiaryTemplate {
    static let dailyCheck = DiaryTemplate(
        id: UUID(),
        name: "Check-in Diário",
        description: "Reflexão rápida sobre seu dia e estado emocional",
        prompts: [
            JournalPrompt(question: "Como você está se sentindo agora?", type: .mood, isRequired: true),
            JournalPrompt(question: "Qual foi o destaque do seu dia?", type: .text),
            JournalPrompt(question: "Houve algo que te deixou ansioso hoje?", type: .text),
            JournalPrompt(question: "Pelo que você é grato hoje?", type: .text),
            JournalPrompt(question: "Como está seu nível de energia? (1-10)", type: .scale, isRequired: true)
        ],
        category: .daily,
        estimatedTime: 5,
        icon: "sun.max"
    )
    
    static let anxietyTracking = DiaryTemplate(
        id: UUID(),
        name: "Rastreamento de Ansiedade",
        description: "Monitore seus níveis de ansiedade e identifique padrões",
        prompts: [
            JournalPrompt(question: "Qual seu nível de ansiedade agora? (1-10)", type: .scale, isRequired: true),
            JournalPrompt(question: "O que pode ter causado essa ansiedade?", type: .text),
            JournalPrompt(question: "Quais sintomas físicos você está sentindo?", type: .tags),
            JournalPrompt(question: "Que estratégias você usou para lidar com isso?", type: .text),
            JournalPrompt(question: "O quão eficazes foram essas estratégias? (1-10)", type: .scale)
        ],
        category: .anxiety,
        estimatedTime: 8,
        icon: "heart.circle"
    )
    
    static let gratitudePractice = DiaryTemplate(
        id: UUID(),
        name: "Prática de Gratidão",
        description: "Cultive uma mentalidade positiva através da gratidão",
        prompts: [
            JournalPrompt(question: "Liste 3 coisas pelas quais você é grato hoje", type: .text, isRequired: true),
            JournalPrompt(question: "Descreva uma pessoa que fez diferença no seu dia", type: .text),
            JournalPrompt(question: "Qual pequeno momento trouxe alegria hoje?", type: .text),
            JournalPrompt(question: "Como você pode expressar gratidão a alguém?", type: .text)
        ],
        category: .gratitude,
        estimatedTime: 6,
        icon: "heart.fill"
    )
    
    static let allTemplates: [DiaryTemplate] = [
        dailyCheck,
        anxietyTracking,
        gratitudePractice
    ]
}
