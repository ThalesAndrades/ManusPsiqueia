//
//  SubscriptionManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import StoreKit
import Combine

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isLoading = false
    @Published var subscriptions: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionGroupStatus: RenewalState?
    @Published var currentTransaction: Transaction?
    
    // Premium features access
    @Published var hasActivePremiumSubscription = false
    @Published var premiumFeatures: [PremiumFeature] = []
    
    // Subscription status tracking
    @Published var subscriptionStatus: SubscriptionStatus = .inactive
    @Published var expirationDate: Date?
    @Published var isTrialing = false
    @Published var trialEndDate: Date?
    
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // Product IDs - These should match your App Store Connect configuration
    private let productIDs = [
        "com.manuspsiqueia.premium.monthly",
        "com.manuspsiqueia.premium.annual",
        "com.manuspsiqueia.psychologist.monthly",
        "com.manuspsiqueia.psychologist.annual"
    ]
    
    enum SubscriptionStatus {
        case inactive
        case active
        case expired
        case expiringSoon
        case trial
    }
    
    struct PremiumFeature: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let icon: String
        let isAvailable: Bool
    }
    
    override init() {
        super.init()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load initial subscription state
        Task {
            await loadSubscriptions()
            await updateCurrentEntitlements()
        }
        
        setupPremiumFeatures()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Premium Features Setup
    private func setupPremiumFeatures() {
        premiumFeatures = [
            PremiumFeature(
                name: "Entradas Ilimitadas",
                description: "Escreva quantas entradas quiser no seu diário",
                icon: "infinity",
                isAvailable: hasActivePremiumSubscription
            ),
            PremiumFeature(
                name: "Análises com IA",
                description: "Insights profundos sobre seus padrões emocionais",
                icon: "brain.head.profile",
                isAvailable: hasActivePremiumSubscription
            ),
            PremiumFeature(
                name: "Relatórios Avançados",
                description: "Gráficos e estatísticas detalhadas do seu progresso",
                icon: "chart.line.uptrend.xyaxis",
                isAvailable: hasActivePremiumSubscription
            ),
            PremiumFeature(
                name: "Backup Automático",
                description: "Seus dados sempre seguros na nuvem",
                icon: "icloud.and.arrow.up",
                isAvailable: hasActivePremiumSubscription
            ),
            PremiumFeature(
                name: "Relatórios por Email",
                description: "Resumos semanais personalizados",
                icon: "envelope",
                isAvailable: hasActivePremiumSubscription
            )
        ]
    }
    
    // MARK: - Public Methods
    func loadSubscriptions() async {
        isLoading = true
        
        do {
            let products = try await Product.products(for: productIDs)
            await MainActor.run {
                self.subscriptions = products.sorted(by: { $0.price < $1.price })
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Failed to load subscriptions: \(error)")
            }
        }
    }
    
    func purchase(product: Product) async throws -> Transaction? {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = checkVerified(verification)
            await updateCurrentEntitlements()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            try await AppStore.sync()
            await updateCurrentEntitlements()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    func updateCurrentEntitlements() async {
        var foundPremiumSubscription = false
        var tempExpirationDate: Date?
        var tempTrialEndDate: Date?
        var tempIsTrialing = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = checkVerified(result)
                
                if productIDs.contains(transaction.productID) {
                    foundPremiumSubscription = true
                    
                    // Check if it's a trial
                    if let subscriptionInfo = transaction.subscriptionInfo {
                        tempExpirationDate = subscriptionInfo.expirationDate
                        
                        if subscriptionInfo.introductoryOffer != nil {
                            tempIsTrialing = true
                            tempTrialEndDate = subscriptionInfo.expirationDate
                        }
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            self.hasActivePremiumSubscription = foundPremiumSubscription
            self.expirationDate = tempExpirationDate
            self.isTrialing = tempIsTrialing
            self.trialEndDate = tempTrialEndDate
            
            // Update subscription status
            if foundPremiumSubscription {
                if tempIsTrialing {
                    self.subscriptionStatus = .trial
                } else if let expDate = tempExpirationDate {
                    let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
                    if daysUntilExpiration <= 0 {
                        self.subscriptionStatus = .expired
                        self.hasActivePremiumSubscription = false
                    } else if daysUntilExpiration <= 7 {
                        self.subscriptionStatus = .expiringSoon
                    } else {
                        self.subscriptionStatus = .active
                    }
                } else {
                    self.subscriptionStatus = .active
                }
            } else {
                self.subscriptionStatus = .inactive
            }
            
            // Update premium features availability
            self.setupPremiumFeatures()
        }
    }
    
    // MARK: - Transaction Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCurrentEntitlements()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // MARK: - Subscription Info
    func getSubscriptionInfo(for productID: String) -> (title: String, description: String, price: String) {
        guard let product = subscriptions.first(where: { $0.id == productID }) else {
            return ("Desconhecido", "", "")
        }
        
        switch productID {
        case "com.manuspsiqueia.premium.monthly":
            return ("Premium Mensal", "Acesso completo por 1 mês", product.displayPrice)
        case "com.manuspsiqueia.premium.annual":
            return ("Premium Anual", "Acesso completo por 1 ano", product.displayPrice)
        case "com.manuspsiqueia.psychologist.monthly":
            return ("Psicólogo Mensal", "Conta profissional por 1 mês", product.displayPrice)
        case "com.manuspsiqueia.psychologist.annual":
            return ("Psicólogo Anual", "Conta profissional por 1 ano", product.displayPrice)
        default:
            return (product.displayName, product.description, product.displayPrice)
        }
    }
    
    // MARK: - Feature Access
    func canAccessFeature(_ feature: String) -> Bool {
        switch feature {
        case "unlimited_entries", "ai_analysis", "advanced_reports", "cloud_backup", "email_reports":
            return hasActivePremiumSubscription
        case "basic_diary":
            return true
        default:
            return false
        }
    }
    
    func getFeatureLimit(_ feature: String) -> Int? {
        if hasActivePremiumSubscription {
            return nil // Unlimited
        }
        
        switch feature {
        case "diary_entries":
            return 5 // Free users can create 5 entries
        case "ai_analysis":
            return 0 // Premium only
        default:
            return nil
        }
    }
    
    // MARK: - Trial Management
    func startFreeTrial() async throws -> Bool {
        // Implementation for starting free trial
        // This would typically involve purchasing a product with trial period
        guard let trialProduct = subscriptions.first(where: { $0.id.contains("monthly") }) else {
            throw StoreError.productNotFound
        }
        
        let transaction = try await purchase(product: trialProduct)
        return transaction != nil
    }
    
    func getRemainingTrialDays() -> Int {
        guard isTrialing, let trialEnd = trialEndDate else { return 0 }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
        return max(0, days)
    }
    
    // MARK: - User-Friendly Methods
    var subscriptionStatusDescription: String {
        switch subscriptionStatus {
        case .inactive:
            return "Nenhuma assinatura ativa"
        case .active:
            return "Assinatura ativa"
        case .expired:
            return "Assinatura expirada"
        case .expiringSoon:
            if let expDate = expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return "Expira em \(formatter.string(from: expDate))"
            }
            return "Expirando em breve"
        case .trial:
            let days = getRemainingTrialDays()
            return "Teste grátis - \(days) dias restantes"
        }
    }
    
    var subscriptionStatusColor: Color {
        switch subscriptionStatus {
        case .inactive:
            return DesignSystem.Colors.secondaryLabel
        case .active:
            return DesignSystem.Colors.success
        case .expired:
            return DesignSystem.Colors.error
        case .expiringSoon:
            return DesignSystem.Colors.warning
        case .trial:
            return DesignSystem.Colors.info
        }
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Falha na verificação da compra"
        case .productNotFound:
            return "Produto não encontrado"
        case .purchaseFailed:
            return "Falha na compra"
        }
    }
}

// MARK: - SKPaymentTransactionObserver Conformance
extension SubscriptionManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Handle legacy StoreKit transactions if needed
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                Task {
                    await updateCurrentEntitlements()
                }
                queue.finishTransaction(transaction)
            case .failed:
                queue.finishTransaction(transaction)
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }
}