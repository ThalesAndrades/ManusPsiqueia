//
//  FlowManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Flow Types
public enum AppFlow {
    case authentication
    case onboarding
    case paywall
    case subscription
    case diary
    case insights
    case goals
    case profile
    case settings
}

public enum FlowState {
    case idle
    case inProgress
    case completed
    case failed(Error)
}

// MARK: - Flow Event
public struct FlowEvent {
    let flowType: AppFlow
    let action: String
    let timestamp: Date
    let metadata: [String: Any]
    
    init(flowType: AppFlow, action: String, metadata: [String: Any] = [:]) {
        self.flowType = flowType
        self.action = action
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Flow Manager
@MainActor
public class FlowManager: ObservableObject {
    static let shared = FlowManager()
    
    @Published var currentFlow: AppFlow?
    @Published var flowState: FlowState = .idle
    @Published var navigationPath = NavigationPath()
    @Published var showPaywall = false
    @Published var showOnboarding = false
    
    private var flowEvents: [FlowEvent] = []
    private var cancellables = Set<AnyCancellable>()
    private let auditLogger = AuditLogger.shared
    
    // Deep link handling
    @Published var pendingDeepLink: URL?
    
    init() {
        setupFlowObservers()
    }
    
    // MARK: - Flow Control
    
    /// Starts a new flow and tracks its progress
    func startFlow(_ flow: AppFlow, metadata: [String: Any] = [:]) {
        currentFlow = flow
        flowState = .inProgress
        
        let event = FlowEvent(flowType: flow, action: "started", metadata: metadata)
        trackFlowEvent(event)
        
        auditLogger.log(
            event: .userAction,
            severity: .info,
            details: "Flow started: \(flow)"
        )
        
        // Handle specific flow initialization
        switch flow {
        case .authentication:
            handleAuthenticationFlow()
        case .onboarding:
            handleOnboardingFlow()
        case .paywall:
            handlePaywallFlow()
        case .subscription:
            handleSubscriptionFlow()
        case .diary:
            handleDiaryFlow()
        case .insights:
            handleInsightsFlow()
        case .goals:
            handleGoalsFlow()
        case .profile:
            handleProfileFlow()
        case .settings:
            handleSettingsFlow()
        }
    }
    
    /// Completes the current flow
    func completeFlow(metadata: [String: Any] = [:]) {
        guard let currentFlow = currentFlow else { return }
        
        flowState = .completed
        
        let event = FlowEvent(flowType: currentFlow, action: "completed", metadata: metadata)
        trackFlowEvent(event)
        
        auditLogger.log(
            event: .userAction,
            severity: .info,
            details: "Flow completed: \(currentFlow)"
        )
        
        // Reset flow state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentFlow = nil
            self.flowState = .idle
        }
    }
    
    /// Fails the current flow with an error
    func failFlow(error: Error, metadata: [String: Any] = [:]) {
        guard let currentFlow = currentFlow else { return }
        
        flowState = .failed(error)
        
        var errorMetadata = metadata
        errorMetadata["error"] = error.localizedDescription
        
        let event = FlowEvent(flowType: currentFlow, action: "failed", metadata: errorMetadata)
        trackFlowEvent(event)
        
        auditLogger.log(
            event: .networkRequestFailed,
            severity: .error,
            details: "Flow failed: \(currentFlow) - \(error.localizedDescription)"
        )
    }
    
    // MARK: - Deep Link Handling
    
    /// Handles incoming deep links
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "manuspsiqueia" else {
            auditLogger.log(
                event: .userAction,
                severity: .warning,
                details: "Invalid deep link scheme: \(url.scheme ?? "none")"
            )
            return
        }
        
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        auditLogger.log(
            event: .userAction,
            severity: .info,
            details: "Handling deep link: \(url.absoluteString)"
        )
        
        switch host {
        case "diary":
            handleDiaryDeepLink(pathComponents: pathComponents)
        case "insights":
            startFlow(.insights)
        case "goals":
            handleGoalsDeepLink(pathComponents: pathComponents)
        case "profile":
            startFlow(.profile)
        case "subscription":
            startFlow(.paywall)
        case "settings":
            handleSettingsDeepLink(pathComponents: pathComponents)
        default:
            pendingDeepLink = url
            auditLogger.log(
                event: .userAction,
                severity: .warning,
                details: "Unhandled deep link: \(url.absoluteString)"
            )
        }
    }
    
    // MARK: - Private Flow Handlers
    
    private func handleAuthenticationFlow() {
        // Authentication flow logic
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .authentication, action: "initialized", metadata: metadata))
    }
    
    private func handleOnboardingFlow() {
        showOnboarding = true
        let metadata = ["first_time": !UserDefaults.standard.bool(forKey: "hasShownOnboarding")]
        trackFlowEvent(FlowEvent(flowType: .onboarding, action: "initialized", metadata: metadata))
    }
    
    private func handlePaywallFlow() {
        showPaywall = true
        let metadata = ["trigger": "manual"]
        trackFlowEvent(FlowEvent(flowType: .paywall, action: "presented", metadata: metadata))
    }
    
    private func handleSubscriptionFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .subscription, action: "initialized", metadata: metadata))
    }
    
    private func handleDiaryFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .diary, action: "accessed", metadata: metadata))
    }
    
    private func handleInsightsFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .insights, action: "accessed", metadata: metadata))
    }
    
    private func handleGoalsFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .goals, action: "accessed", metadata: metadata))
    }
    
    private func handleProfileFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .profile, action: "accessed", metadata: metadata))
    }
    
    private func handleSettingsFlow() {
        let metadata = ["source": "flow_manager"]
        trackFlowEvent(FlowEvent(flowType: .settings, action: "accessed", metadata: metadata))
    }
    
    // MARK: - Deep Link Specific Handlers
    
    private func handleDiaryDeepLink(pathComponents: [String]) {
        if pathComponents.first == "new" {
            let metadata = ["action": "new_entry", "source": "deep_link"]
            startFlow(.diary, metadata: metadata)
        } else if pathComponents.first == "entry", pathComponents.count > 1 {
            let entryId = pathComponents[1]
            let metadata = ["action": "view_entry", "entry_id": entryId, "source": "deep_link"]
            startFlow(.diary, metadata: metadata)
        } else {
            startFlow(.diary)
        }
    }
    
    private func handleGoalsDeepLink(pathComponents: [String]) {
        if pathComponents.first == "new" {
            let metadata = ["action": "new_goal", "source": "deep_link"]
            startFlow(.goals, metadata: metadata)
        } else {
            startFlow(.goals)
        }
    }
    
    private func handleSettingsDeepLink(pathComponents: [String]) {
        let section = pathComponents.first ?? "general"
        let metadata = ["section": section, "source": "deep_link"]
        startFlow(.settings, metadata: metadata)
    }
    
    // MARK: - Flow Analytics
    
    private func trackFlowEvent(_ event: FlowEvent) {
        flowEvents.append(event)
        
        // Keep only last 100 events to prevent memory issues
        if flowEvents.count > 100 {
            flowEvents.removeFirst(flowEvents.count - 100)
        }
        
        // Send analytics event
        NotificationCenter.default.post(
            name: .flowEventTracked,
            object: event
        )
    }
    
    /// Gets flow events for analytics
    func getFlowEvents(for flowType: AppFlow? = nil) -> [FlowEvent] {
        if let flowType = flowType {
            return flowEvents.filter { $0.flowType == flowType }
        }
        return flowEvents
    }
    
    /// Gets flow completion rate for a specific flow type
    func getFlowCompletionRate(for flowType: AppFlow) -> Double {
        let events = getFlowEvents(for: flowType)
        let startedEvents = events.filter { $0.action == "started" }
        let completedEvents = events.filter { $0.action == "completed" }
        
        guard !startedEvents.isEmpty else { return 0.0 }
        
        return Double(completedEvents.count) / Double(startedEvents.count)
    }
    
    // MARK: - Flow State Management
    
    private func setupFlowObservers() {
        // Observe authentication state changes
        NotificationCenter.default.publisher(for: .authenticationStateChanged)
            .sink { [weak self] _ in
                self?.handleAuthenticationStateChange()
            }
            .store(in: &cancellables)
        
        // Observe subscription state changes
        NotificationCenter.default.publisher(for: .subscriptionStateChanged)
            .sink { [weak self] _ in
                self?.handleSubscriptionStateChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthenticationStateChange() {
        // Handle authentication state changes in flow context
        if currentFlow == .authentication {
            completeFlow(metadata: ["trigger": "auth_state_change"])
        }
    }
    
    private func handleSubscriptionStateChange() {
        // Handle subscription state changes in flow context
        if currentFlow == .subscription || currentFlow == .paywall {
            completeFlow(metadata: ["trigger": "subscription_state_change"])
        }
    }
    
    // MARK: - Flow Recovery
    
    /// Recovers from a failed flow state
    func recoverFromFailedFlow() {
        guard case .failed(let error) = flowState else { return }
        
        auditLogger.log(
            event: .userAction,
            severity: .info,
            details: "Recovering from failed flow: \(error.localizedDescription)"
        )
        
        currentFlow = nil
        flowState = .idle
        
        // Clear any UI state
        showPaywall = false
        showOnboarding = false
        navigationPath = NavigationPath()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let flowEventTracked = Notification.Name("flowEventTracked")
    static let authenticationStateChanged = Notification.Name("authenticationStateChanged")
    static let subscriptionStateChanged = Notification.Name("subscriptionStateChanged")
}

// MARK: - Flow Error Types
public enum FlowError: LocalizedError {
    case invalidDeepLink(URL)
    case flowInProgress
    case authenticationRequired
    case subscriptionRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidDeepLink(let url):
            return "Deep link inválido: \(url.absoluteString)"
        case .flowInProgress:
            return "Outro fluxo está em andamento"
        case .authenticationRequired:
            return "Autenticação necessária para continuar"
        case .subscriptionRequired:
            return "Assinatura necessária para acessar este recurso"
        }
    }
}