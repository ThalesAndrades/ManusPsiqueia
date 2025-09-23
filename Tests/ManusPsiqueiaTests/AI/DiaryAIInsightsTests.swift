//
//  DiaryAIInsightsTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

/// Testes para o sistema de IA de insights do diário
/// Cobertura: Análise de sentimento, anonimização, insights e ética
final class DiaryAIInsightsTests: XCTestCase {
    
    var aiManager: DiaryAIInsightsManager!
    var sampleEntries: [DiaryEntry]!
    
    override func setUpWithError() throws {
        super.setUp()
        
        aiManager = DiaryAIInsightsManager()
        aiManager.configureTestMode()
        
        // Criar entradas de exemplo para testes
        sampleEntries = [
            DiaryEntry(
                id: UUID(),
                patientId: UUID(),
                content: "Hoje me senti muito ansioso com a apresentação no trabalho. Não consegui dormir bem.",
                mood: 3,
                anxiety: 8,
                energy: 4,
                tags: ["trabalho", "ansiedade", "sono"],
                symptoms: ["insônia", "nervosismo"],
                triggers: ["apresentação", "pressão"],
                strategies: ["respiração"],
                createdAt: Date()
            ),
            DiaryEntry(
                id: UUID(),
                patientId: UUID(),
                content: "Dia muito bom! Consegui terminar o projeto e me senti realizado. Dormi bem.",
                mood: 8,
                anxiety: 2,
                energy: 9,
                tags: ["trabalho", "sucesso"],
                symptoms: [],
                triggers: [],
                strategies: ["organização"],
                createdAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            ),
            DiaryEntry(
                id: UUID(),
                patientId: UUID(),
                content: "Discussão com família me deixou triste. Sinto que não me entendem.",
                mood: 2,
                anxiety: 6,
                energy: 3,
                tags: ["família", "tristeza"],
                symptoms: ["tristeza", "isolamento"],
                triggers: ["conflito familiar"],
                strategies: ["caminhada"],
                createdAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            )
        ]
    }
    
    override func tearDownWithError() throws {
        aiManager = nil
        sampleEntries = nil
        super.tearDown()
    }
    
    // MARK: - Testes de Anonimização
    
    func testDataAnonymization() throws {
        let entry = sampleEntries[0]
        let anonymizedData = aiManager.anonymizeEntry(entry)
        
        // Verificar que dados pessoais foram removidos
        XCTAssertFalse(anonymizedData.contains("apresentação"))
        XCTAssertFalse(anonymizedData.contains("trabalho"))
        
        // Verificar que métricas foram preservadas
        XCTAssertTrue(anonymizedData.contains("mood_rating"))
        XCTAssertTrue(anonymizedData.contains("anxiety_level"))
        XCTAssertTrue(anonymizedData.contains("energy_level"))
    }
    
    func testSentimentAnalysis() throws {
        let positiveEntry = sampleEntries[1]
        let negativeEntry = sampleEntries[2]
        
        let positiveSentiment = aiManager.analyzeSentiment(positiveEntry.content)
        let negativeSentiment = aiManager.analyzeSentiment(negativeEntry.content)
        
        XCTAssertGreaterThan(positiveSentiment.score, 0.5)
        XCTAssertEqual(positiveSentiment.label, .positive)
        
        XCTAssertLessThan(negativeSentiment.score, -0.5)
        XCTAssertEqual(negativeSentiment.label, .negative)
    }
    
    // MARK: - Testes de Insights
    
    func testMoodPatternAnalysis() throws {
        let expectation = XCTestExpectation(description: "Mood pattern analyzed")
        
        aiManager.analyzeMoodPatterns(sampleEntries) { result in
            switch result {
            case .success(let insights):
                XCTAssertNotNil(insights.moodTrend)
                XCTAssertNotNil(insights.averageMood)
                XCTAssertGreaterThan(insights.dataPoints.count, 0)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Mood pattern analysis failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAnxietyCorrelationAnalysis() throws {
        let expectation = XCTestExpectation(description: "Anxiety correlation analyzed")
        
        aiManager.analyzeAnxietyCorrelations(sampleEntries) { result in
            switch result {
            case .success(let insights):
                XCTAssertNotNil(insights.primaryTriggers)
                XCTAssertNotNil(insights.correlationFactors)
                XCTAssertGreaterThan(insights.triggerFrequency.count, 0)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Anxiety correlation analysis failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testProgressTracking() throws {
        let expectation = XCTestExpectation(description: "Progress tracked")
        
        aiManager.trackProgress(sampleEntries, timeframe: .week) { result in
            switch result {
            case .success(let progress):
                XCTAssertNotNil(progress.overallImprovement)
                XCTAssertNotNil(progress.moodStability)
                XCTAssertNotNil(progress.anxietyReduction)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Progress tracking failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Testes de Insights Profissionais
    
    func testProfessionalInsightsGeneration() throws {
        let expectation = XCTestExpectation(description: "Professional insights generated")
        
        aiManager.generateProfessionalInsights(
            for: sampleEntries,
            psychologistId: UUID()
        ) { result in
            switch result {
            case .success(let insights):
                XCTAssertNotNil(insights.clinicalObservations)
                XCTAssertNotNil(insights.recommendedInterventions)
                XCTAssertNotNil(insights.riskAssessment)
                XCTAssertNotNil(insights.sessionFocus)
                
                // Verificar que não há dados pessoais
                let insightsText = insights.description
                XCTAssertFalse(insightsText.contains("apresentação"))
                XCTAssertFalse(insightsText.contains("família"))
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Professional insights generation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testRiskAssessment() throws {
        // Criar entrada com indicadores de risco
        let riskEntry = DiaryEntry(
            id: UUID(),
            patientId: UUID(),
            content: "Não vejo mais sentido em nada. Sinto que sou um fardo para todos.",
            mood: 1,
            anxiety: 9,
            energy: 1,
            tags: ["desesperança"],
            symptoms: ["tristeza profunda", "desesperança"],
            triggers: ["isolamento"],
            strategies: [],
            createdAt: Date()
        )
        
        let riskAssessment = aiManager.assessRisk([riskEntry])
        
        XCTAssertEqual(riskAssessment.level, .high)
        XCTAssertTrue(riskAssessment.requiresImmediateAttention)
        XCTAssertGreaterThan(riskAssessment.riskFactors.count, 0)
    }
    
    // MARK: - Testes de Ética e Privacidade
    
    func testDataPrivacyCompliance() throws {
        let entry = sampleEntries[0]
        
        // Verificar que dados originais nunca são transmitidos
        let processedData = aiManager.prepareForAnalysis(entry)
        
        XCTAssertFalse(processedData.containsPersonalInfo)
        XCTAssertTrue(processedData.isAnonymized)
        XCTAssertNotNil(processedData.encryptionHash)
    }
    
    func testConsentValidation() throws {
        let patientId = UUID()
        
        // Testar sem consentimento
        XCTAssertFalse(aiManager.hasValidConsent(for: patientId))
        
        // Dar consentimento
        aiManager.grantConsent(for: patientId, type: .aiAnalysis)
        XCTAssertTrue(aiManager.hasValidConsent(for: patientId))
        
        // Revogar consentimento
        aiManager.revokeConsent(for: patientId)
        XCTAssertFalse(aiManager.hasValidConsent(for: patientId))
    }
    
    func testDataRetentionPolicy() throws {
        let oldEntry = DiaryEntry(
            id: UUID(),
            patientId: UUID(),
            content: "Entrada antiga",
            mood: 5,
            anxiety: 5,
            energy: 5,
            tags: [],
            symptoms: [],
            triggers: [],
            strategies: [],
            createdAt: Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        )
        
        let shouldRetain = aiManager.shouldRetainData(oldEntry)
        XCTAssertFalse(shouldRetain) // Dados > 1 ano devem ser removidos
    }
    
    // MARK: - Testes de Performance
    
    func testAnalysisPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            aiManager.analyzeMoodPatterns(sampleEntries) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testBatchProcessingPerformance() throws {
        // Criar muitas entradas para teste de performance
        var largeDataset: [DiaryEntry] = []
        for i in 0..<100 {
            let entry = DiaryEntry(
                id: UUID(),
                patientId: UUID(),
                content: "Entrada de teste \(i)",
                mood: Int.random(in: 1...10),
                anxiety: Int.random(in: 1...10),
                energy: Int.random(in: 1...10),
                tags: ["teste"],
                symptoms: [],
                triggers: [],
                strategies: [],
                createdAt: Date()
            )
            largeDataset.append(entry)
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Batch processing performance")
            
            aiManager.batchAnalyze(largeDataset) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Testes de Error Handling
    
    func testInvalidDataHandling() throws {
        let invalidEntry = DiaryEntry(
            id: UUID(),
            patientId: UUID(),
            content: "", // Conteúdo vazio
            mood: -1, // Valor inválido
            anxiety: 15, // Valor fora do range
            energy: 0,
            tags: [],
            symptoms: [],
            triggers: [],
            strategies: [],
            createdAt: Date()
        )
        
        let expectation = XCTestExpectation(description: "Invalid data handled")
        
        aiManager.analyzeMoodPatterns([invalidEntry]) { result in
            switch result {
            case .success:
                XCTFail("Should have failed with invalid data")
            case .failure(let error):
                XCTAssertTrue(error.isValidationError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAPIErrorHandling() throws {
        let expectation = XCTestExpectation(description: "API error handled")
        
        // Simular erro de API
        aiManager.simulateAPIError = true
        
        aiManager.generateProfessionalInsights(
            for: sampleEntries,
            psychologistId: UUID()
        ) { result in
            switch result {
            case .success:
                XCTFail("Should have failed with API error")
            case .failure(let error):
                XCTAssertTrue(error.isNetworkError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
