import Foundation
import SwiftKeychainWrapper

@_exported import Foundation

/// ManusPsiqueiaCore - Core business logic and models
/// 
/// This module contains:
/// - Core data models (User, Subscription, Payment, etc.)
/// - Business logic managers
/// - Security components
/// - Utility functions
/// 
/// This module is designed to be platform-agnostic and contains no UI dependencies.
public struct ManusPsiqueiaCore {
    
    public static let version = "1.0.0"
    
    /// Initialize the core module with default configuration
    public static func initialize() {
        // Core module initialization logic
        print("ManusPsiqueiaCore v\(version) initialized")
    }
}

// MARK: - Core Module Exports
// Export all core types and managers for easy access
@_exported import SwiftKeychainWrapper