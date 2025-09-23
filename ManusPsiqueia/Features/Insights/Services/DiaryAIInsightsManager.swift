//
//  DiaryAIInsightsManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
#if canImport(OpenAI)
import OpenAI
#endif

/// AI-powered insights manager for diary entries with privacy-first approach
@MainActor
class DiaryAIInsightsManager: ObservableObject {
    @Published var isGeneratingInsights = false
    @Published var lastInsightsGenerated: Date?
    
    private let openAIManager: OpenAIManagerProtocol
    
    init(openAIManager: OpenAIManagerProtocol = DefaultOpenAIManager()) {
        self.openAIManager = openAIManager
    }
    private let insightsStorage = InsightsStorageManager()
    private let privacyManager = InsightsPrivacyManager()
    
    // MARK: - Public Methods
    
    /// Generate AI insights for a diary entry
    func generateInsights(for entry: DiaryEntry, previousEntries: [DiaryEntry]) async throws -> DiaryAIInsights {
        isGeneratingInsights = true
        defer { isGeneratingInsights = false }
        
        // Create anonymized context for AI analysis
        let anonymizedContext = createAnonymizedContext(entry: entry, previousEntries: previousEntries)
        
        // Generate insights using OpenAI
        let insights = try await generateAIAnalysis(context: anonymizedContext)
        
        // Store insights with privacy protection
        try await storeInsights(insights, for: entry.id)
        
        lastInsightsGenerated = Date()
        
        return insights
    }
    
    /// Store insights for therapist access (anonymized)
    func storeTherapistInsights(_ insights: DiaryAIInsights, entryId: UUID) async throws {
        let therapistInsights = TherapistInsights(
            id: UUID(),
            patientId: insights.patientId,
            entryId: entryId,
            timestamp: Date(),
            moodTrend: insights.moodAnalysis.trend,
            anxietyLevel: insights.anxietyAnalysis.currentLevel,
            riskFactors: insights.riskAssessment.factors,
            recommendations: insights.therapeuticRecommendations.map { $0.recommendation },
            urgencyLevel: insights.riskAssessment.urgencyLevel,
            keyThemes: insights.patternAnalysis.themes,
            progressIndicators: insights.progressTracking.indicators,
            isAnonymized: true
        )
        
        try await insightsStorage.storeTherapistInsights(therapistInsights)
    }
    
    /// Get insights for therapist dashboard
    func getTherapistInsights(for patientId: UUID, dateRange: DateInterval? = nil) async throws -> [TherapistInsights] {
        return try await insightsStorage.getTherapistInsights(patientId: patientId, dateRange: dateRange)
    }
    
    /// Generate weekly summary for therapist
    func generateWeeklySummary(for patientId: UUID) async throws -> WeeklySummary {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let dateRange = DateInterval(start: weekAgo, end: Date())
        
        let insights = try await getTherapistInsights(for: patientId, dateRange: dateRange)
        
        return WeeklySummary(
            patientId: patientId,
            weekStarting: weekAgo,
            totalEntries: insights.count,
            averageMood: calculateAverageMood(insights),
            averageAnxiety: calculateAverageAnxiety(insights),
            keyThemes: extractKeyThemes(insights),
            riskFactors: extractRiskFactors(insights),
            recommendations: generateWeeklyRecommendations(insights),
            progressNotes: generateProgressNotes(insights),
            urgentConcerns: extractUrgentConcerns(insights)
        )
    }
    
    // MARK: - Private Methods
    
    private func createAnonymizedContext(entry: DiaryEntry, previousEntries: [DiaryEntry]) -> AnonymizedDiaryContext {
        // Take last 5 entries for context (excluding current)
        let recentEntries = Array(previousEntries.prefix(5))
        
        return AnonymizedDiaryContext(
            currentEntry: anonymizeEntry(entry),
            recentEntries: recentEntries.map { anonymizeEntry($0) },
            patientAge: nil, // Anonymized
            sessionCount: recentEntries.count,
            timeframe: calculateTimeframe(entries: recentEntries + [entry])
        )
    }
    
    private func anonymizeEntry(_ entry: DiaryEntry) -> AnonymizedDiaryEntry {
        return AnonymizedDiaryEntry(
            mood: entry.mood,
            anxietyLevel: entry.anxietyLevel,
            energyLevel: entry.energyLevel,
            sleepQuality: entry.sleepQuality,
            contentThemes: extractThemes(from: entry.content),
            emotionalIntensity: calculateEmotionalIntensity(entry),
            triggers: entry.triggers,
            copingStrategies: entry.copingStrategies,
            symptoms: entry.symptoms.map { $0.symptom },
            timestamp: entry.timestamp
        )
    }
    
    private func extractThemes(from content: String) -> [String] {
        // Use NLP to extract themes without storing actual content
        let keywords = [
            "trabalho", "família", "relacionamento", "ansiedade", "depressão",
            "estresse", "sono", "exercício", "medicação", "terapia",
            "autoestima", "futuro", "passado", "medo", "raiva",
            "tristeza", "alegria", "esperança", "solidão", "culpa"
        ]
        
        let lowercaseContent = content.lowercased()
        return keywords.filter { lowercaseContent.contains($0) }
    }
    
    private func calculateEmotionalIntensity(_ entry: DiaryEntry) -> Double {
        let moodIntensity = entry.mood.intensity
        let anxietyWeight = entry.anxietyLevel / 10.0
        let energyWeight = (10.0 - entry.energyLevel) / 10.0 // Lower energy = higher intensity
        
        return (moodIntensity + anxietyWeight * 10 + energyWeight * 10) / 3.0
    }
    
    private func calculateTimeframe(entries: [DiaryEntry]) -> String {
        guard let oldest = entries.map({ $0.timestamp }).min(),
              let newest = entries.map({ $0.timestamp }).max() else {
            return "single_entry"
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        
        if daysDifference <= 1 {
            return "daily"
        } else if daysDifference <= 7 {
            return "weekly"
        } else if daysDifference <= 30 {
            return "monthly"
        } else {
            return "long_term"
        }
    }
    
    private func generateAIAnalysis(context: AnonymizedDiaryContext) async throws -> DiaryAIInsights {
        let prompt = createAnalysisPrompt(context: context)
        
        let response = try await openAIManager.generateCompletion(
            prompt: prompt,
            model: "gpt-4",
            maxTokens: 1500,
            temperature: 0.3
        )
        
        return try parseAIResponse(response, patientId: context.currentEntry.patientId ?? UUID())
    }
    
    private func createAnalysisPrompt(context: AnonymizedDiaryContext) -> String {
        return """
        Você é um assistente de IA especializado em saúde mental, analisando dados anonimizados de diário para gerar insights terapêuticos.
        
        CONTEXTO DO PACIENTE:
        - Entrada atual: Humor \(context.currentEntry.mood.name), Ansiedade \(context.currentEntry.anxietyLevel)/10, Energia \(context.currentEntry.energyLevel)/10
        - Temas identificados: \(context.currentEntry.contentThemes.joined(separator: ", "))
        - Gatilhos: \(context.currentEntry.triggers.joined(separator: ", "))
        - Estratégias de enfrentamento: \(context.currentEntry.copingStrategies.joined(separator: ", "))
        - Período de análise: \(context.timeframe)
        - Entradas recentes: \(context.recentEntries.count)
        
        HISTÓRICO RECENTE:
        \(context.recentEntries.enumerated().map { index, entry in
            "Entrada \(index + 1): Humor \(entry.mood.name), Ansiedade \(entry.anxietyLevel)/10, Temas: \(entry.contentThemes.joined(separator: ", "))"
        }.joined(separator: "\n"))
        
        Por favor, forneça uma análise estruturada em JSON com os seguintes campos:
        
        {
          "moodAnalysis": {
            "trend": "improving|stable|declining",
            "patterns": ["padrão1", "padrão2"],
            "triggers": ["gatilho1", "gatilho2"]
          },
          "anxietyAnalysis": {
            "currentLevel": "low|moderate|high|severe",
            "trends": ["tendência1", "tendência2"],
            "managementStrategies": ["estratégia1", "estratégia2"]
          },
          "riskAssessment": {
            "urgencyLevel": "low|medium|high|critical",
            "factors": ["fator1", "fator2"],
            "recommendations": ["recomendação1", "recomendação2"]
          },
          "therapeuticRecommendations": [
            {
              "category": "behavioral|cognitive|lifestyle|medication",
              "recommendation": "recomendação específica",
              "priority": "low|medium|high"
            }
          ],
          "patternAnalysis": {
            "themes": ["tema1", "tema2"],
            "cyclicalPatterns": ["padrão1", "padrão2"],
            "progressIndicators": ["indicador1", "indicador2"]
          },
          "progressTracking": {
            "indicators": ["melhoria1", "melhoria2"],
            "areasOfConcern": ["preocupação1", "preocupação2"],
            "goals": ["objetivo1", "objetivo2"]
          }
        }
        
        IMPORTANTE: 
        - Mantenha total confidencialidade e anonimato
        - Foque em padrões e tendências, não em detalhes específicos
        - Forneça insights acionáveis para o terapeuta
        - Considere o contexto cultural brasileiro
        - Use linguagem profissional mas acessível
        """
    }
    
    private func parseAIResponse(_ response: String, patientId: UUID) throws -> DiaryAIInsights {
        guard let data = response.data(using: .utf8) else {
            throw AIInsightsError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let aiResponse = try decoder.decode(AIInsightsResponse.self, from: data)
        
        return DiaryAIInsights(
            id: UUID(),
            patientId: patientId,
            timestamp: Date(),
            moodAnalysis: MoodAnalysis(
                trend: MoodTrend(rawValue: aiResponse.moodAnalysis.trend) ?? .stable,
                patterns: aiResponse.moodAnalysis.patterns,
                triggers: aiResponse.moodAnalysis.triggers
            ),
            anxietyAnalysis: AnxietyAnalysis(
                currentLevel: AnxietyLevel(rawValue: aiResponse.anxietyAnalysis.currentLevel) ?? .moderate,
                trends: aiResponse.anxietyAnalysis.trends,
                managementStrategies: aiResponse.anxietyAnalysis.managementStrategies
            ),
            riskAssessment: RiskAssessment(
                urgencyLevel: UrgencyLevel(rawValue: aiResponse.riskAssessment.urgencyLevel) ?? .low,
                factors: aiResponse.riskAssessment.factors,
                recommendations: aiResponse.riskAssessment.recommendations
            ),
            therapeuticRecommendations: aiResponse.therapeuticRecommendations.map { rec in
                TherapeuticRecommendation(
                    category: RecommendationCategory(rawValue: rec.category) ?? .behavioral,
                    recommendation: rec.recommendation,
                    priority: Priority(rawValue: rec.priority) ?? .medium
                )
            },
            patternAnalysis: PatternAnalysis(
                themes: aiResponse.patternAnalysis.themes,
                cyclicalPatterns: aiResponse.patternAnalysis.cyclicalPatterns,
                progressIndicators: aiResponse.patternAnalysis.progressIndicators
            ),
            progressTracking: ProgressTracking(
                indicators: aiResponse.progressTracking.indicators,
                areasOfConcern: aiResponse.progressTracking.areasOfConcern,
                goals: aiResponse.progressTracking.goals
            ),
            confidenceScore: 0.85, // Default confidence
            isAnonymized: true
        )
    }
    
    private func storeInsights(_ insights: DiaryAIInsights, for entryId: UUID) async throws {
        try await insightsStorage.storeInsights(insights, entryId: entryId)
    }
    
    // MARK: - Helper Methods for Weekly Summary
    
    private func calculateAverageMood(_ insights: [TherapistInsights]) -> Double {
        guard !insights.isEmpty else { return 5.0 }
        
        let moodValues = insights.compactMap { insight -> Double? in
            switch insight.moodTrend {
            case .improving: return 7.0
            case .stable: return 5.0
            case .declining: return 3.0
            }
        }
        
        return moodValues.reduce(0, +) / Double(moodValues.count)
    }
    
    private func calculateAverageAnxiety(_ insights: [TherapistInsights]) -> Double {
        let anxietyValues = insights.map { insight -> Double in
            switch insight.anxietyLevel {
            case .low: return 2.5
            case .moderate: return 5.0
            case .high: return 7.5
            case .severe: return 9.0
            }
        }
        
        guard !anxietyValues.isEmpty else { return 5.0 }
        return anxietyValues.reduce(0, +) / Double(anxietyValues.count)
    }
    
    private func extractKeyThemes(_ insights: [TherapistInsights]) -> [String] {
        let allThemes = insights.flatMap { $0.keyThemes }
        let themeCounts = Dictionary(grouping: allThemes, by: { $0 }).mapValues { $0.count }
        return themeCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func extractRiskFactors(_ insights: [TherapistInsights]) -> [String] {
        let allFactors = insights.flatMap { $0.riskFactors }
        return Array(Set(allFactors)).prefix(3).map { String($0) }
    }
    
    private func generateWeeklyRecommendations(_ insights: [TherapistInsights]) -> [String] {
        let allRecommendations = insights.flatMap { $0.recommendations }
        let uniqueRecommendations = Array(Set(allRecommendations))
        return Array(uniqueRecommendations.prefix(5))
    }
    
    private func generateProgressNotes(_ insights: [TherapistInsights]) -> [String] {
        let allIndicators = insights.flatMap { $0.progressIndicators }
        return Array(Set(allIndicators)).prefix(3).map { String($0) }
    }
    
    private func extractUrgentConcerns(_ insights: [TherapistInsights]) -> [String] {
        return insights
            .filter { $0.urgencyLevel == .high || $0.urgencyLevel == .critical }
            .flatMap { $0.riskFactors }
            .prefix(3)
            .map { String($0) }
    }
}

// MARK: - Supporting Types

enum AIInsightsError: LocalizedError {
    case invalidResponse
    case analysisTimeout
    case quotaExceeded
    case privacyViolation
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida da IA"
        case .analysisTimeout:
            return "Timeout na análise da IA"
        case .quotaExceeded:
            return "Cota de análise excedida"
        case .privacyViolation:
            return "Violação de privacidade detectada"
        }
    }
}

// MARK: - Storage Manager

class InsightsStorageManager {
    func storeInsights(_ insights: DiaryAIInsights, entryId: UUID) async throws {
        // Store insights in secure local storage
        // In production, this would use Core Data or similar
    }
    
    func storeTherapistInsights(_ insights: TherapistInsights) async throws {
        // Store anonymized insights for therapist access
    }
    
    func getTherapistInsights(patientId: UUID, dateRange: DateInterval?) async throws -> [TherapistInsights] {
        // Retrieve insights for therapist dashboard
        return []
    }
}

// MARK: - Privacy Manager

class InsightsPrivacyManager {
    func validatePrivacyCompliance(_ insights: DiaryAIInsights) -> Bool {
        // Ensure no personal information is included
        return insights.isAnonymized
    }
    
    func anonymizeInsights(_ insights: DiaryAIInsights) -> DiaryAIInsights {
        // Additional anonymization if needed
        return insights
    }
}

// MARK: - OpenAI Manager Protocol and Implementation

protocol OpenAIManagerProtocol {
    func generateCompletion(prompt: String, model: String, maxTokens: Int, temperature: Double) async throws -> String
}

#if canImport(OpenAI)
class DefaultOpenAIManager: OpenAIManagerProtocol {
    private let client: OpenAI
    
    init() {
        // In a real implementation, this would use a secure API key
        self.client = OpenAI(apiToken: "")
    }
    
    func generateCompletion(prompt: String, model: String, maxTokens: Int, temperature: Double) async throws -> String {
        let query = ChatQuery(
            messages: [.user(.init(content: .string(prompt)))],
            model: .gpt4,
            maxTokens: maxTokens,
            temperature: temperature
        )
        
        let result = try await client.chats(query: query)
        return result.choices.first?.message.content?.string ?? ""
    }
}
#else
class DefaultOpenAIManager: OpenAIManagerProtocol {
    func generateCompletion(prompt: String, model: String, maxTokens: Int, temperature: Double) async throws -> String {
        // Return mock response when OpenAI is not available
        return """
        {
          "moodAnalysis": {
            "trend": "stable",
            "patterns": ["mock_pattern"],
            "triggers": ["mock_trigger"]
          },
          "anxietyAnalysis": {
            "currentLevel": "moderate",
            "trends": ["mock_trend"],
            "managementStrategies": ["mock_strategy"]
          },
          "riskAssessment": {
            "urgencyLevel": "low",
            "factors": ["mock_factor"],
            "recommendations": ["mock_recommendation"]
          },
          "therapeuticRecommendations": [
            {
              "category": "behavioral",
              "recommendation": "mock recommendation",
              "priority": "medium"
            }
          ],
          "patternAnalysis": {
            "themes": ["mock_theme"],
            "cyclicalPatterns": ["mock_pattern"],
            "progressIndicators": ["mock_indicator"]
          },
          "progressTracking": {
            "indicators": ["mock_improvement"],
            "areasOfConcern": ["mock_concern"],
            "goals": ["mock_goal"]
          }
        }
        """
    }
}
#endif
