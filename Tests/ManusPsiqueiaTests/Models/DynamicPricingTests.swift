//
//  DynamicPricingTests.swift
//  ManusPsiqueiaTests
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import XCTest
@testable import ManusPsiqueiaCore
@testable import ManusPsiqueiaUI
@testable import ManusPsiqueiaServices

/// Testes para o sistema de precificação dinâmica
/// Cobertura: Cálculos, tiers, recursos opcionais e validações
final class DynamicPricingTests: XCTestCase {
    
    var pricingCalculator: PricingCalculator!
    
    override func setUpWithError() throws {
        super.setUp()
        pricingCalculator = PricingCalculator()
    }
    
    override func tearDownWithError() throws {
        pricingCalculator = nil
        super.tearDown()
    }
    
    // MARK: - Testes de Cálculo Base
    
    func testStarterTierPricing() throws {
        let plan = PricingPlan(
            patientCount: 5,
            tier: .starter,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertEqual(price, 4990) // R$ 49,90 em centavos
    }
    
    func testProfessionalTierPricing() throws {
        let plan = PricingPlan(
            patientCount: 15,
            tier: .professional,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertEqual(price, 9990) // R$ 99,90 em centavos
    }
    
    func testExpertTierPricing() throws {
        let plan = PricingPlan(
            patientCount: 35,
            tier: .expert,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertEqual(price, 19990) // R$ 199,90 em centavos
    }
    
    func testEnterpriseTierPricing() throws {
        let plan = PricingPlan(
            patientCount: 75,
            tier: .enterprise,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertEqual(price, 39990) // R$ 399,90 em centavos
    }
    
    // MARK: - Testes de Recursos Opcionais
    
    func testAIPremiumFeature() throws {
        let plan = PricingPlan(
            patientCount: 10,
            tier: .professional,
            selectedFeatures: [.aiPremium]
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        let expectedPrice = 9990 + 2990 // Base + AI Premium
        XCTAssertEqual(price, expectedPrice)
    }
    
    func testMultipleFeatures() throws {
        let plan = PricingPlan(
            patientCount: 20,
            tier: .professional,
            selectedFeatures: [.aiPremium, .advancedAnalytics, .prioritySupport]
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        let expectedPrice = 9990 + 2990 + 1990 + 990 // Base + 3 features
        XCTAssertEqual(price, expectedPrice)
    }
    
    // MARK: - Testes de Validação de Tier
    
    func testTierValidationForPatientCount() throws {
        // Starter: até 10 pacientes
        XCTAssertTrue(pricingCalculator.isValidTier(.starter, for: 5))
        XCTAssertTrue(pricingCalculator.isValidTier(.starter, for: 10))
        XCTAssertFalse(pricingCalculator.isValidTier(.starter, for: 15))
        
        // Professional: 11-25 pacientes
        XCTAssertFalse(pricingCalculator.isValidTier(.professional, for: 10))
        XCTAssertTrue(pricingCalculator.isValidTier(.professional, for: 15))
        XCTAssertTrue(pricingCalculator.isValidTier(.professional, for: 25))
        XCTAssertFalse(pricingCalculator.isValidTier(.professional, for: 30))
    }
    
    func testAutomaticTierSuggestion() throws {
        XCTAssertEqual(pricingCalculator.suggestedTier(for: 5), .starter)
        XCTAssertEqual(pricingCalculator.suggestedTier(for: 15), .professional)
        XCTAssertEqual(pricingCalculator.suggestedTier(for: 35), .expert)
        XCTAssertEqual(pricingCalculator.suggestedTier(for: 75), .enterprise)
    }
    
    // MARK: - Testes de Desconto Anual
    
    func testAnnualDiscount() throws {
        let monthlyPlan = PricingPlan(
            patientCount: 15,
            tier: .professional,
            selectedFeatures: [.aiPremium],
            billingCycle: .monthly
        )
        
        let annualPlan = PricingPlan(
            patientCount: 15,
            tier: .professional,
            selectedFeatures: [.aiPremium],
            billingCycle: .annual
        )
        
        let monthlyPrice = pricingCalculator.calculatePrice(for: monthlyPlan)
        let annualPrice = pricingCalculator.calculatePrice(for: annualPlan)
        
        // Desconto de 20% no plano anual
        let expectedAnnualPrice = Int(Double(monthlyPrice * 12) * 0.8)
        XCTAssertEqual(annualPrice, expectedAnnualPrice)
    }
    
    // MARK: - Testes de ROI
    
    func testROICalculation() throws {
        let plan = PricingPlan(
            patientCount: 20,
            tier: .professional,
            selectedFeatures: [.aiPremium]
        )
        
        let roi = pricingCalculator.calculateROI(for: plan, averageSessionPrice: 15000) // R$ 150 por sessão
        
        // ROI deve ser positivo para 20 pacientes com 4 sessões/mês
        XCTAssertGreaterThan(roi.monthlyRevenue, roi.monthlyCost)
        XCTAssertGreaterThan(roi.roiPercentage, 100)
    }
    
    // MARK: - Testes de Upgrade Automático
    
    func testUpgradeRecommendation() throws {
        let currentPlan = PricingPlan(
            patientCount: 10,
            tier: .starter,
            selectedFeatures: []
        )
        
        // Simular crescimento para 15 pacientes
        let recommendation = pricingCalculator.getUpgradeRecommendation(
            currentPlan: currentPlan,
            newPatientCount: 15
        )
        
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.recommendedTier, .professional)
        XCTAssertTrue(recommendation?.shouldUpgrade ?? false)
    }
    
    // MARK: - Testes de Economia
    
    func testSavingsCalculation() throws {
        let manualPlan = PricingPlan(
            patientCount: 20,
            tier: .professional,
            selectedFeatures: []
        )
        
        let savings = pricingCalculator.calculateSavings(
            compared: manualPlan,
            to: .traditionalCompetitor
        )
        
        // Deve mostrar economia vs concorrentes
        XCTAssertGreaterThan(savings.percentageSaved, 0)
        XCTAssertGreaterThan(savings.monthlySavings, 0)
    }
    
    // MARK: - Testes de Performance
    
    func testPricingCalculationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let plan = PricingPlan(
                    patientCount: Int.random(in: 1...100),
                    tier: .professional,
                    selectedFeatures: [.aiPremium, .advancedAnalytics]
                )
                let _ = pricingCalculator.calculatePrice(for: plan)
            }
        }
    }
    
    // MARK: - Testes de Edge Cases
    
    func testZeroPatients() throws {
        let plan = PricingPlan(
            patientCount: 0,
            tier: .starter,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertEqual(price, 0) // Sem pacientes = sem cobrança
    }
    
    func testMaximumPatients() throws {
        let plan = PricingPlan(
            patientCount: 1000,
            tier: .enterprise,
            selectedFeatures: []
        )
        
        let price = pricingCalculator.calculatePrice(for: plan)
        XCTAssertGreaterThan(price, 0)
        
        // Deve usar pricing customizado para volumes altos
        XCTAssertTrue(pricingCalculator.requiresCustomPricing(for: plan))
    }
}
