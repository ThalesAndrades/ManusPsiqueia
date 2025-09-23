//
//  ErrorManager.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import Foundation
import SwiftUI
import UserNotifications

/// Centralized error management system for ManusPsiqueia
/// Provides consistent error handling, logging, and user feedback across the app
@MainActor
final class ErrorManager: ObservableObject {
    
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var errorHistory: [ErrorEvent] = []
    
    private let auditLogger = AuditLogger.shared
    private let maxErrorHistory = 50
    
    private init() {}
    
    // MARK: - Error Management
    
    /// Handles and processes errors throughout the application
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about where the error occurred
    ///   - shouldShowToUser: Whether to display the error to the user
    func handleError(
        _ error: Error,
        context: String? = nil,
        shouldShowToUser: Bool = true
    ) {
        let appError = mapToAppError(error, context: context)
        
        // Log the error
        logError(appError, context: context)
        
        // Add to history
        addToErrorHistory(appError, context: context)
        
        // Show to user if requested
        if shouldShowToUser {
            showErrorToUser(appError)
        }
        
        // Handle critical errors
        if appError.severity == .critical {
            handleCriticalError(appError)
        }
    }
    
    /// Maps any error to standardized AppError
    /// - Parameters:
    ///   - error: Original error
    ///   - context: Additional context
    /// - Returns: Mapped AppError
    private func mapToAppError(_ error: Error, context: String?) -> AppError {
        // If already an AppError, return as is
        if let appError = error as? AppError {
            return appError
        }
        
        // Map known error types
        if let invitationError = error as? InvitationError {
            return mapInvitationError(invitationError)
        }
        
        if let urlError = error as? URLError {
            return mapURLError(urlError)
        }
        
        // Default mapping for unknown errors
        return AppError(
            code: "UNKNOWN_ERROR",
            title: "Erro Inesperado",
            message: error.localizedDescription,
            severity: .medium,
            category: .unknown,
            originalError: error
        )
    }
    
    /// Maps InvitationError to AppError
    private func mapInvitationError(_ error: InvitationError) -> AppError {
        return AppError(
            code: "INVITATION_\(String(describing: error).uppercased())",
            title: "Erro de Convite",
            message: error.localizedDescription,
            severity: .medium,
            category: .invitation,
            originalError: error,
            suggestedAction: "Verifique os dados inseridos e tente novamente"
        )
    }
    
    /// Maps URLError to AppError
    private func mapURLError(_ error: URLError) -> AppError {
        let severity: ErrorSeverity = error.code == .notConnectedToInternet ? .high : .medium
        
        return AppError(
            code: "NETWORK_\(error.code.rawValue)",
            title: "Erro de Conexão",
            message: getNetworkErrorMessage(error),
            severity: severity,
            category: .network,
            originalError: error,
            suggestedAction: "Verifique sua conexão com a internet e tente novamente"
        )
    }
    
    /// Gets user-friendly message for network errors
    private func getNetworkErrorMessage(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "Sem conexão com a internet"
        case .timedOut:
            return "Tempo limite da conexão excedido"
        case .cannotConnectToHost:
            return "Não foi possível conectar ao servidor"
        case .networkConnectionLost:
            return "Conexão com a internet foi perdida"
        default:
            return "Erro de rede: \(error.localizedDescription)"
        }
    }
    
    /// Logs error with appropriate level
    private func logError(_ error: AppError, context: String?) {
        let severity: AuditLogSeverity = switch error.severity {
        case .low: .info
        case .medium: .warning
        case .high: .high
        case .critical: .critical
        }
        
        var details: [String: Any] = [
            "error_code": error.code,
            "error_category": error.category.rawValue,
            "error_title": error.title,
            "error_message": error.message
        ]
        
        if let context = context {
            details["context"] = context
        }
        
        if let originalError = error.originalError {
            details["original_error"] = String(describing: originalError)
        }
        
        auditLogger.log(
            event: .errorOccurred,
            details: details,
            severity: severity
        )
    }
    
    /// Adds error to history with automatic cleanup
    private func addToErrorHistory(_ error: AppError, context: String?) {
        let errorEvent = ErrorEvent(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        errorHistory.append(errorEvent)
        
        // Keep only recent errors
        if errorHistory.count > maxErrorHistory {
            errorHistory = Array(errorHistory.suffix(maxErrorHistory))
        }
    }
    
    /// Shows error to user via UI
    private func showErrorToUser(_ error: AppError) {
        currentError = error
        isShowingError = true
        
        // Also send local notification for high/critical errors
        if error.severity == .high || error.severity == .critical {
            sendErrorNotification(error)
        }
    }
    
    /// Handles critical errors that require immediate attention
    private func handleCriticalError(_ error: AppError) {
        // Log critical error
        print("🚨 CRITICAL ERROR: \(error.title) - \(error.message)")
        
        // Send crash report (in production)
        if Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String == "ManusPsiqueia" {
            sendCrashReport(error)
        }
        
        // Reset app state if necessary
        if error.category == .security {
            resetAppSecurityState()
        }
    }
    
    /// Sends local notification for important errors
    private func sendErrorNotification(_ error: AppError) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(error.title)"
        content.body = error.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "error_\(error.code)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Sends crash report for critical errors
    private func sendCrashReport(_ error: AppError) {
        // In production, integrate with crash reporting service
        print("📊 Sending crash report for: \(error.code)")
    }
    
    /// Resets app security state for security-related critical errors
    private func resetAppSecurityState() {
        // Clear sensitive data
        // Reset authentication state
        // Clear biometric settings
        print("🔒 Resetting app security state due to critical security error")
    }
    
    // MARK: - Public Methods
    
    /// Dismisses current error
    func dismissCurrentError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Clears error history
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    /// Gets error statistics
    func getErrorStatistics() -> ErrorStatistics {
        let total = errorHistory.count
        let byCategory = Dictionary(grouping: errorHistory, by: { $0.error.category })
        let bySeverity = Dictionary(grouping: errorHistory, by: { $0.error.severity })
        
        return ErrorStatistics(
            totalErrors: total,
            errorsByCategory: byCategory.mapValues { $0.count },
            errorsBySeverity: bySeverity.mapValues { $0.count },
            mostRecentError: errorHistory.last?.timestamp
        )
    }
}

// MARK: - Supporting Types

/// Standardized application error
struct AppError: Error, Identifiable {
    let id = UUID()
    let code: String
    let title: String
    let message: String
    let severity: ErrorSeverity
    let category: ErrorCategory
    let originalError: Error?
    let suggestedAction: String?
    let timestamp: Date
    
    init(
        code: String,
        title: String,
        message: String,
        severity: ErrorSeverity,
        category: ErrorCategory,
        originalError: Error? = nil,
        suggestedAction: String? = nil
    ) {
        self.code = code
        self.title = title
        self.message = message
        self.severity = severity
        self.category = category
        self.originalError = originalError
        self.suggestedAction = suggestedAction
        self.timestamp = Date()
    }
}

/// Error severity levels
enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var description: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        case .critical: return "Crítica"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "❌"
        case .critical: return "🚨"
        }
    }
}

/// Error categories
enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case invitation = "invitation"
    case authentication = "authentication"
    case payment = "payment"
    case security = "security"
    case validation = "validation"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .network: return "Rede"
        case .invitation: return "Convites"
        case .authentication: return "Autenticação"
        case .payment: return "Pagamentos"
        case .security: return "Segurança"
        case .validation: return "Validação"
        case .unknown: return "Desconhecido"
        }
    }
}

/// Error event for history tracking
struct ErrorEvent {
    let error: AppError
    let context: String?
    let timestamp: Date
}

/// Error statistics for reporting
struct ErrorStatistics {
    let totalErrors: Int
    let errorsByCategory: [ErrorCategory: Int]
    let errorsBySeverity: [ErrorSeverity: Int]
    let mostRecentError: Date?
}

/// Extension to add error event to audit logger
extension AuditLogEvent {
    static let errorOccurred = AuditLogEvent(rawValue: "error_occurred")
}