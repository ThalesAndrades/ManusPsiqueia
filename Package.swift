// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManusPsiqueia",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        // Stripe iOS SDK
        .package(
            url: "https://github.com/stripe/stripe-ios",
            from: "23.0.0"
        ),
        // Supabase Swift SDK (for backend)
        .package(
            url: "https://github.com/supabase/supabase-swift",
            from: "2.0.0"
        ),
        // OpenAI Swift SDK (for AI features)
        .package(
            url: "https://github.com/MacPaw/OpenAI",
            from: "0.2.0"
        ),
        // Keychain wrapper for secure storage
        .package(
            url: "https://github.com/jrendel/SwiftKeychainWrapper",
            from: "4.0.0"
        )
    ],
    targets: [
        .target(
            name: "ManusPsiqueia",
            dependencies: [
                .product(name: "Stripe", package: "stripe-ios", condition: .when(platforms: [.iOS])),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper", condition: .when(platforms: [.iOS])),
                "ManusPsiqueiaUI",
                "ManusPsiqueiaServices"
            ],
            path: "ManusPsiqueia"
        ),
        .target(
            name: "ManusPsiqueiaUI",
            dependencies: [],
            path: "Modules/ManusPsiqueiaUI/Sources/ManusPsiqueiaUI"
        ),
        .target(
            name: "ManusPsiqueiaServices",
            dependencies: [
                .product(name: "Stripe", package: "stripe-ios", condition: .when(platforms: [.iOS])),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "OpenAI", package: "OpenAI")
            ],
            path: "Modules/ManusPsiqueiaServices/Sources/ManusPsiqueiaServices"
        ),
        // Basic test target that doesn't depend on iOS-specific modules
        .testTarget(
            name: "ManusPsiqueiaTests",
            dependencies: [],
            path: "ManusPsiqueiaTests"
        ),
        // iOS-specific test target for full integration testing
        .testTarget(
            name: "ManusPsiqueiaIntegrationTests",
            dependencies: ["ManusPsiqueia"],
            path: "Tests/ManusPsiqueiaIntegrationTests"
        )
    ]
)
