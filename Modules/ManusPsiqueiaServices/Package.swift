// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManusPsiqueiaServices",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ManusPsiqueiaServices",
            targets: ["ManusPsiqueiaServices"]
        ),
    ],
    dependencies: [
        // Stripe iOS SDK
        .package(
            url: "https://github.com/stripe/stripe-ios",
            from: "23.0.0"
        ),
        // Supabase Swift SDK
        .package(
            url: "https://github.com/supabase/supabase-swift",
            from: "2.0.0"
        ),
        // OpenAI Swift SDK
        .package(
            url: "https://github.com/MacPaw/OpenAI",
            from: "0.2.0"
        ),
        // Keychain wrapper
        .package(
            url: "https://github.com/jrendel/SwiftKeychainWrapper",
            from: "4.0.0"
        )
    ],
    targets: [
        .target(
            name: "ManusPsiqueiaServices",
            dependencies: [
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
                .product(name: "StripePayments", package: "stripe-ios"),
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ],
            path: "Sources/ManusPsiqueiaServices"
        ),
        .testTarget(
            name: "ManusPsiqueiaServicesTests",
            dependencies: ["ManusPsiqueiaServices"],
            path: "Tests/ManusPsiqueiaServicesTests"
        ),
    ]
)
