import Foundation
import Combine
import ManusPsiqueiaCore

// External service integrations
import Stripe
import StripePaymentSheet
import StripePayments
import StripePaymentsUI
import Supabase
import OpenAI

@_exported import Combine

/// ManusPsiqueiaServices - External service integrations
/// 
/// This module contains:
/// - Payment processing (Stripe)
/// - Backend communication (Supabase)
/// - AI services (OpenAI)
/// - Network services and API clients
/// 
/// This module handles all external service integrations and dependencies.
public struct ManusPsiqueiaServices {
    
    public static let version = "1.0.0"
    
    /// Initialize the services module
    public static func initialize() {
        // Services module initialization logic
        print("ManusPsiqueiaServices v\(version) initialized")
    }
}

// MARK: - Service Configuration
public struct ServiceConfiguration {
    public static var supabaseURL: String = ""
    public static var supabaseKey: String = ""
    public static var stripePublishableKey: String = ""
    public static var openAIKey: String = ""
    
    public static func configure(
        supabaseURL: String,
        supabaseKey: String,
        stripeKey: String,
        openAIKey: String
    ) {
        self.supabaseURL = supabaseURL
        self.supabaseKey = supabaseKey
        self.stripePublishableKey = stripeKey
        self.openAIKey = openAIKey
    }
}