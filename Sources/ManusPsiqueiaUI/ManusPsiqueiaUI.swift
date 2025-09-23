import SwiftUI
import ManusPsiqueiaCore

@_exported import SwiftUI

/// ManusPsiqueiaUI - User Interface components and views
/// 
/// This module contains:
/// - SwiftUI components and views
/// - UI-specific managers and utilities
/// - Custom styling and animations
/// - Reusable UI components
/// 
/// This module depends on ManusPsiqueiaCore for business logic.
public struct ManusPsiqueiaUI {
    
    public static let version = "1.0.0"
    
    /// Initialize the UI module with default theme
    public static func initialize() {
        // UI module initialization logic
        print("ManusPsiqueiaUI v\(version) initialized")
    }
}

// MARK: - UI Module Configuration
public struct UIConfiguration {
    public static var primaryColor: Color = .blue
    public static var secondaryColor: Color = .gray
    public static var backgroundColor: Color = .white
    
    public static func setupDefaultTheme() {
        // Setup default theme colors and styles
    }
}