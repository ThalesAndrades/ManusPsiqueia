//
//  DiaryAIModels.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Main AI Insights Model

/// Comprehensive AI insights generated from diary entries
struct DiaryAIInsights: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let timestamp: Date
    let moodAnalysis: MoodAnalysis
    let anxietyAnalysis: AnxietyAnalysis
    let riskAssessment: RiskAssessment
    let therapeuticRecommendations: [TherapeuticRecommendation]
    let patternAnalysis: PatternAnalysis
    let progressTracking: ProgressTracking
    let confidenceScore: Double // 0.0 - 1.0
    let isAnonymized: Bool
    
    init(
        id: UUID = UUID(),
        patientId: UUID,
        timestamp: Date = Date(),
        moodAnalysis: MoodAnalysis,
        anxietyAnalysis: AnxietyAnalysis,
        riskAssessment: RiskAssessment,
        therapeuticRecommendations: [TherapeuticRecommendation],
        patternAnalysis: PatternAnalysis,
        progressTracking: ProgressTracking,
        confidenceScore: Double,
        isAnonymized: Bool = true
    ) {
        self.id = id
        self.patientId = patientId
        self.timestamp = timestamp
        self.moodAnalysis = moodAnalysis
        self.anxietyAnalysis = anxietyAnalysis
        self.riskAssessment = riskAssessment
        self.therapeuticRecommendations = therapeuticRecommendations
        self.patternAnalysis = patternAnalysis
        self.progressTracking = progressTracking
        self.confidenceScore = confidenceScore
        self.isAnonymized = isAnonymized
    }
}

// MARK: - Mood Analysis

struct MoodAnalysis: Codable {
    let trend: MoodTrend
    let patterns: [String]
    let triggers: [String]
    
    var trendDescription: String {
        switch trend {
        case .improving:
            return "Humor em melhoria consistente"
        case .stable:
            return "Humor estável"
        case .declining:
            return "Humor em declínio - requer atenção"
        }
    }
    
    var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

enum MoodTrend: String, Codable, CaseIterable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Anxiety Analysis

struct AnxietyAnalysis: Codable {
    let currentLevel: AnxietyLevel
    let trends: [String]
    let managementStrategies: [String]
    
    var levelDescription: String {
        switch currentLevel {
        case .low:
            return "Ansiedade em níveis baixos"
        case .moderate:
            return "Ansiedade moderada"
        case .high:
            return "Ansiedade elevada - intervenção recomendada"
        case .severe:
            return "Ansiedade severa - atenção imediata necessária"
        }
    }
    
    var levelColor: Color {
        switch currentLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

enum AnxietyLevel: String, Codable, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case severe = "severe"
    
    var numericValue: Double {
        switch self {
        case .low: return 2.5
        case .moderate: return 5.0
        case .high: return 7.5
        case .severe: return 9.0
        }
    }
}

// MARK: - Risk Assessment

struct RiskAssessment: Codable {
    let urgencyLevel: UrgencyLevel
    let factors: [String]
    let recommendations: [String]
    
    var urgencyDescription: String {
        switch urgencyLevel {
        case .low:
            return "Baixo risco - monitoramento de rotina"
        case .medium:
            return "Risco moderado - acompanhamento próximo"
        case .high:
            return "Alto risco - intervenção necessária"
        case .critical:
            return "Risco crítico - ação imediata requerida"
        }
    }
    
    var urgencyColor: Color {
        switch urgencyLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum UrgencyLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Therapeutic Recommendations

struct TherapeuticRecommendation: Identifiable, Codable {
    let id: UUID
    let category: RecommendationCategory
    let recommendation: String
    let priority: Priority
    let estimatedDuration: String?
    let expectedOutcome: String?
    
    init(
        category: RecommendationCategory,
        recommendation: String,
        priority: Priority,
        estimatedDuration: String? = nil,
        expectedOutcome: String? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.recommendation = recommendation
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.expectedOutcome = expectedOutcome
    }
    
    var categoryColor: Color {
        category.color
    }
    
    var priorityColor: Color {
        priority.color
    }
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case behavioral = "behavioral"
    case cognitive = "cognitive"
    case lifestyle = "lifestyle"
    case medication = "medication"
    case social = "social"
    case therapeutic = "therapeutic"
    
    var name: String {
        switch self {
        case .behavioral: return "Comportamental"
        case .cognitive: return "Cognitiva"
        case .lifestyle: return "Estilo de Vida"
        case .medication: return "Medicação"
        case .social: return "Social"
        case .therapeutic: return "Terapêutica"
        }
    }
    
    var icon: String {
        switch self {
        case .behavioral: return "figure.walk"
        case .cognitive: return "brain.head.profile"
        case .lifestyle: return "heart.fill"
        case .medication: return "pills"
        case .social: return "person.2.fill"
        case .therapeutic: return "stethoscope"
        }
    }
    
    var color: Color {
        switch self {
        case .behavioral: return .blue
        case .cognitive: return .purple
        case .lifestyle: return .green
        case .medication: return .red
        case .social: return .orange
        case .therapeutic: return .teal
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var name: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    var weight: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

// MARK: - Pattern Analysis

struct PatternAnalysis: Codable {
    let themes: [String]
    let cyclicalPatterns: [String]
    let progressIndicators: [String]
    
    var hasPositivePatterns: Bool {
        let positiveKeywords = ["melhoria", "progresso", "crescimento", "estabilidade", "força"]
        return progressIndicators.contains { indicator in
            positiveKeywords.contains { indicator.lowercased().contains($0) }
        }
    }
    
    var hasConcerningPatterns: Bool {
        let concerningKeywords = ["declínio", "piora", "isolamento", "desesperança", "risco"]
        return themes.contains { theme in
            concerningKeywords.contains { theme.lowercased().contains($0) }
        }
    }
}

// MARK: - Progress Tracking

struct ProgressTracking: Codable {
    let indicators: [String]
    let areasOfConcern: [String]
    let goals: [String]
    
    var overallProgress: ProgressStatus {
        let positiveCount = indicators.count
        let concernCount = areasOfConcern.count
        
        if positiveCount > concernCount * 2 {
            return .improving
        } else if positiveCount >= concernCount {
            return .stable
        } else {
            return .needsAttention
        }
    }
}

enum ProgressStatus: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case needsAttention = "needs_attention"
    
    var description: String {
        switch self {
        case .improving: return "Progresso positivo"
        case .stable: return "Progresso estável"
        case .needsAttention: return "Requer atenção"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .needsAttention: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Therapist Insights (Anonymized)

struct TherapistInsights: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let entryId: UUID
    let timestamp: Date
    let moodTrend: MoodTrend
    let anxietyLevel: AnxietyLevel
    let riskFactors: [String]
    let recommendations: [String]
    let urgencyLevel: UrgencyLevel
    let keyThemes: [String]
    let progressIndicators: [String]
    let isAnonymized: Bool
    
    var riskScore: Double {
        let urgencyWeight = Double(urgencyLevel.priority) * 0.4
        let anxietyWeight = anxietyLevel.numericValue * 0.3
        let factorWeight = Double(riskFactors.count) * 0.3
        
        return min(10.0, urgencyWeight + anxietyWeight + factorWeight)
    }
}

// MARK: - Weekly Summary

struct WeeklySummary: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let weekStarting: Date
    let totalEntries: Int
    let averageMood: Double
    let averageAnxiety: Double
    let keyThemes: [String]
    let riskFactors: [String]
    let recommendations: [String]
    let progressNotes: [String]
    let urgentConcerns: [String]
    
    init(
        patientId: UUID,
        weekStarting: Date,
        totalEntries: Int,
        averageMood: Double,
        averageAnxiety: Double,
        keyThemes: [String],
        riskFactors: [String],
        recommendations: [String],
        progressNotes: [String],
        urgentConcerns: [String]
    ) {
        self.id = UUID()
        self.patientId = patientId
        self.weekStarting = weekStarting
        self.totalEntries = totalEntries
        self.averageMood = averageMood
        self.averageAnxiety = averageAnxiety
        self.keyThemes = keyThemes
        self.riskFactors = riskFactors
        self.recommendations = recommendations
        self.progressNotes = progressNotes
        self.urgentConcerns = urgentConcerns
    }
    
    var engagementLevel: EngagementLevel {
        if totalEntries >= 5 {
            return .high
        } else if totalEntries >= 3 {
            return .medium
        } else {
            return .low
        }
    }
    
    var overallStatus: WeeklyStatus {
        if !urgentConcerns.isEmpty {
            return .needsAttention
        } else if averageMood >= 6.0 && averageAnxiety <= 5.0 {
            return .positive
        } else {
            return .stable
        }
    }
}

enum EngagementLevel: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .low: return "Baixo engajamento"
        case .medium: return "Engajamento moderado"
        case .high: return "Alto engajamento"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .red
        case .medium: return .yellow
        case .high: return .green
        }
    }
}

enum WeeklyStatus: String, Codable {
    case positive = "positive"
    case stable = "stable"
    case needsAttention = "needs_attention"
    
    var description: String {
        switch self {
        case .positive: return "Semana positiva"
        case .stable: return "Semana estável"
        case .needsAttention: return "Requer atenção"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .stable: return .blue
        case .needsAttention: return .orange
        }
    }
}

// MARK: - Anonymized Context Models

struct AnonymizedDiaryContext: Codable {
    let currentEntry: AnonymizedDiaryEntry
    let recentEntries: [AnonymizedDiaryEntry]
    let patientAge: Int?
    let sessionCount: Int
    let timeframe: String
}

struct AnonymizedDiaryEntry: Codable {
    let patientId: UUID?
    let mood: MoodState
    let anxietyLevel: Double
    let energyLevel: Double
    let sleepQuality: Double?
    let contentThemes: [String]
    let emotionalIntensity: Double
    let triggers: [String]
    let copingStrategies: [String]
    let symptoms: [String]
    let timestamp: Date
}

// MARK: - AI Response Models

struct AIInsightsResponse: Codable {
    let moodAnalysis: MoodAnalysisResponse
    let anxietyAnalysis: AnxietyAnalysisResponse
    let riskAssessment: RiskAssessmentResponse
    let therapeuticRecommendations: [TherapeuticRecommendationResponse]
    let patternAnalysis: PatternAnalysisResponse
    let progressTracking: ProgressTrackingResponse
}

struct MoodAnalysisResponse: Codable {
    let trend: String
    let patterns: [String]
    let triggers: [String]
}

struct AnxietyAnalysisResponse: Codable {
    let currentLevel: String
    let trends: [String]
    let managementStrategies: [String]
}

struct RiskAssessmentResponse: Codable {
    let urgencyLevel: String
    let factors: [String]
    let recommendations: [String]
}

struct TherapeuticRecommendationResponse: Codable {
    let category: String
    let recommendation: String
    let priority: String
}

struct PatternAnalysisResponse: Codable {
    let themes: [String]
    let cyclicalPatterns: [String]
    let progressIndicators: [String]
}

struct ProgressTrackingResponse: Codable {
    let indicators: [String]
    let areasOfConcern: [String]
    let goals: [String]
}

// MARK: - Extensions

extension DiaryAIInsights {
    var overallRiskLevel: UrgencyLevel {
        return riskAssessment.urgencyLevel
    }
    
    var highPriorityRecommendations: [TherapeuticRecommendation] {
        return therapeuticRecommendations.filter { $0.priority == .high }
    }
    
    var isPositiveProgress: Bool {
        return moodAnalysis.trend == .improving && 
               anxietyAnalysis.currentLevel == .low &&
               progressTracking.overallProgress == .improving
    }
    
    var requiresImmediateAttention: Bool {
        return riskAssessment.urgencyLevel == .critical ||
               riskAssessment.urgencyLevel == .high
    }
}

extension TherapistInsights {
    static func sortByUrgency(_ insights: [TherapistInsights]) -> [TherapistInsights] {
        return insights.sorted { $0.urgencyLevel.priority > $1.urgencyLevel.priority }
    }
    
    static func filterByRiskLevel(_ insights: [TherapistInsights], minLevel: UrgencyLevel) -> [TherapistInsights] {
        return insights.filter { $0.urgencyLevel.priority >= minLevel.priority }
    }
}
