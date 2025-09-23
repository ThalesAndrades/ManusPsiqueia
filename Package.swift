// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManusPsiqueia",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        // Stripe iOS SDK with Connect support
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
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "StripePayments", package: "stripe-ios"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
                .product(name: "StripePaymentsUI", package: "stripe-ios"),
                .product(name: "StripeConnect", package: "stripe-ios"),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ]
        ),
        .testTarget(
            name: "ManusPsiqueiaTests",
            dependencies: ["ManusPsiqueia"]
        )
    ]
)
