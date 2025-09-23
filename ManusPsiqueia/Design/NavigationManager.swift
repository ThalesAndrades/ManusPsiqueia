//
//  NavigationManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable, CaseIterable {
    // Authentication Flow
    case onboarding
    case userTypeSelection
    case registration(UserType)
    case login
    case forgotPassword
    
    // Main App Flow
    case dashboard
    case profile
    case settings
    
    // Psychologist Flow
    case psychologistDashboard
    case patientManagement
    case financialDashboard
    case subscription
    case withdrawFunds
    
    // Patient Flow
    case patientDashboard
    case diary
    case newDiaryEntry
    case aiAnalysis(DiaryEntry?)
    case insights
    case goals
    
    // Paywall Flow
    case paywall
    case subscriptionPlans
    case payment
    
    // Support Flow
    case help
    case contactSupport
    case privacyPolicy
    case termsOfService
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .userTypeSelection: return "userTypeSelection"
        case .registration(let userType): return "registration_\(userType.rawValue)"
        case .login: return "login"
        case .forgotPassword: return "forgotPassword"
        case .dashboard: return "dashboard"
        case .profile: return "profile"
        case .settings: return "settings"
        case .psychologistDashboard: return "psychologistDashboard"
        case .patientManagement: return "patientManagement"
        case .financialDashboard: return "financialDashboard"
        case .subscription: return "subscription"
        case .withdrawFunds: return "withdrawFunds"
        case .patientDashboard: return "patientDashboard"
        case .diary: return "diary"
        case .newDiaryEntry: return "newDiaryEntry"
        case .aiAnalysis: return "aiAnalysis"
        case .insights: return "insights"
        case .goals: return "goals"
        case .paywall: return "paywall"
        case .subscriptionPlans: return "subscriptionPlans"
        case .payment: return "payment"
        case .help: return "help"
        case .contactSupport: return "contactSupport"
        case .privacyPolicy: return "privacyPolicy"
        case .termsOfService: return "termsOfService"
        }
    }
}

// MARK: - Navigation Manager
@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var navigationPath = NavigationPath()
    @Published var currentTab: TabDestination = .diary
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenDestination?
    @Published var showAlert = false
    @Published var alertConfig: AlertConfig?
    
    // Navigation history for analytics and debugging
    @Published private(set) var navigationHistory: [NavigationEvent] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNavigationTracking()
    }
    
    // MARK: - Tab Destinations
    enum TabDestination: String, CaseIterable {
        case diary = "diary"
        case insights = "insights"
        case goals = "goals"
        case profile = "profile"
        case settings = "settings"
        
        var title: String {
            switch self {
            case .diary: return "Diário"
            case .insights: return "Insights"
            case .goals: return "Metas"
            case .profile: return "Perfil"
            case .settings: return "Configurações"
            }
        }
        
        var icon: String {
            switch self {
            case .diary: return "book.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .goals: return "target"
            case .profile: return "person.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var iconSelected: String {
            switch self {
            case .diary: return "book.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .goals: return "target"
            case .profile: return "person.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Sheet Destinations
    enum SheetDestination: Identifiable {
        case userTypeSelection
        case paywall
        case settings
        case profile
        case newDiaryEntry
        case subscriptionPlans
        case help
        
        var id: String {
            switch self {
            case .userTypeSelection: return "userTypeSelection"
            case .paywall: return "paywall"
            case .settings: return "settings"
            case .profile: return "profile"
            case .newDiaryEntry: return "newDiaryEntry"
            case .subscriptionPlans: return "subscriptionPlans"
            case .help: return "help"
            }
        }
    }
    
    // MARK: - Full Screen Cover Destinations
    enum FullScreenDestination: Identifiable {
        case onboarding
        case authentication
        case subscription
        
        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .authentication: return "authentication"
            case .subscription: return "subscription"
            }
        }
    }
    
    // MARK: - Navigation Event
    struct NavigationEvent {
        let timestamp: Date
        let action: NavigationAction
        let destination: String
        let source: String?
        
        enum NavigationAction {
            case push
            case pop
            case popToRoot
            case tabChange
            case sheetPresent
            case sheetDismiss
            case fullScreenPresent
            case fullScreenDismiss
        }
    }
    
    // MARK: - Alert Configuration
    struct AlertConfig: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let primaryButton: AlertButton
        let secondaryButton: AlertButton?
        
        struct AlertButton {
            let title: String
            let style: ButtonStyle
            let action: () -> Void
            
            enum ButtonStyle {
                case `default`
                case cancel
                case destructive
            }
        }
    }
    
    // MARK: - Navigation Methods
    func navigate(to destination: NavigationDestination) {
        DesignSystem.Haptics.light()
        navigationPath.append(destination)
        trackNavigation(.push, to: destination.id)
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        DesignSystem.Haptics.light()
        navigationPath.removeLast()
        trackNavigation(.pop, to: "previous")
    }
    
    func popToRoot() {
        guard !navigationPath.isEmpty else { return }
        DesignSystem.Haptics.medium()
        navigationPath.removeLast(navigationPath.count)
        trackNavigation(.popToRoot, to: "root")
    }
    
    func switchTab(to tab: TabDestination) {
        guard currentTab != tab else { return }
        DesignSystem.Haptics.selection()
        currentTab = tab
        trackNavigation(.tabChange, to: tab.rawValue, from: currentTab.rawValue)
    }
    
    func presentSheet(_ sheet: SheetDestination) {
        DesignSystem.Haptics.light()
        presentedSheet = sheet
        trackNavigation(.sheetPresent, to: sheet.id)
    }
    
    func dismissSheet() {
        guard presentedSheet != nil else { return }
        DesignSystem.Haptics.light()
        let currentSheet = presentedSheet?.id ?? "unknown"
        presentedSheet = nil
        trackNavigation(.sheetDismiss, to: currentSheet)
    }
    
    func presentFullScreenCover(_ cover: FullScreenDestination) {
        DesignSystem.Haptics.medium()
        presentedFullScreenCover = cover
        trackNavigation(.fullScreenPresent, to: cover.id)
    }
    
    func dismissFullScreenCover() {
        guard presentedFullScreenCover != nil else { return }
        DesignSystem.Haptics.medium()
        let currentCover = presentedFullScreenCover?.id ?? "unknown"
        presentedFullScreenCover = nil
        trackNavigation(.fullScreenDismiss, to: currentCover)
    }
    
    // MARK: - Alert Methods
    func showAlert(
        title: String,
        message: String,
        primaryButton: AlertConfig.AlertButton,
        secondaryButton: AlertConfig.AlertButton? = nil
    ) {
        DesignSystem.Haptics.warning()
        alertConfig = AlertConfig(
            title: title,
            message: message,
            primaryButton: primaryButton,
            secondaryButton: secondaryButton
        )
        showAlert = true
    }
    
    func showError(_ error: Error) {
        showAlert(
            title: "Erro",
            message: error.localizedDescription,
            primaryButton: AlertConfig.AlertButton(
                title: "OK",
                style: .default,
                action: {}
            )
        )
    }
    
    func showSuccess(message: String, action: (() -> Void)? = nil) {
        DesignSystem.Haptics.success()
        showAlert(
            title: "Sucesso",
            message: message,
            primaryButton: AlertConfig.AlertButton(
                title: "OK",
                style: .default,
                action: action ?? {}
            )
        )
    }
    
    func showConfirmation(
        title: String,
        message: String,
        confirmAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        showAlert(
            title: title,
            message: message,
            primaryButton: AlertConfig.AlertButton(
                title: "Confirmar",
                style: .destructive,
                action: confirmAction
            ),
            secondaryButton: AlertConfig.AlertButton(
                title: "Cancelar",
                style: .cancel,
                action: cancelAction ?? {}
            )
        )
    }
    
    // MARK: - Deep Link Support
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "diary":
            switchTab(to: .diary)
            if components.path == "/new" {
                presentSheet(.newDiaryEntry)
            }
        case "insights":
            switchTab(to: .insights)
        case "profile":
            switchTab(to: .profile)
        case "settings":
            presentSheet(.settings)
        case "paywall":
            presentSheet(.paywall)
        default:
            break
        }
    }
    
    // MARK: - Navigation Tracking
    private func trackNavigation(
        _ action: NavigationEvent.NavigationAction,
        to destination: String,
        from source: String? = nil
    ) {
        let event = NavigationEvent(
            timestamp: Date(),
            action: action,
            destination: destination,
            source: source
        )
        navigationHistory.append(event)
        
        // Keep only last 100 events to avoid memory issues
        if navigationHistory.count > 100 {
            navigationHistory.removeFirst(navigationHistory.count - 100)
        }
        
        // Analytics tracking can be added here
        print("Navigation: \(action) to \(destination)")
    }
    
    private func setupNavigationTracking() {
        // Track tab changes
        $currentTab
            .dropFirst()
            .sink { [weak self] newTab in
                self?.trackNavigation(.tabChange, to: newTab.rawValue)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Accessibility Support
    func announceNavigation(to destination: String) {
        let announcement = "Navegando para \(destination)"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    // MARK: - State Restoration
    func saveNavigationState() {
        // Save current navigation state for app restoration
        let state = [
            "currentTab": currentTab.rawValue,
            "navigationPathCount": navigationPath.count
        ]
        UserDefaults.standard.set(state, forKey: "NavigationState")
    }
    
    func restoreNavigationState() {
        guard let state = UserDefaults.standard.dictionary(forKey: "NavigationState"),
              let tabRawValue = state["currentTab"] as? String,
              let tab = TabDestination(rawValue: tabRawValue) else { return }
        
        currentTab = tab
    }
}

// MARK: - Navigation Environment Key
struct NavigationManagerKey: EnvironmentKey {
    static let defaultValue = NavigationManager.shared
}

extension EnvironmentValues {
    var navigationManager: NavigationManager {
        get { self[NavigationManagerKey.self] }
        set { self[NavigationManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func navigationManager(_ manager: NavigationManager = NavigationManager.shared) -> some View {
        environment(\.navigationManager, manager)
    }
}