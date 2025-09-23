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
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper"),
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
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Modules/ManusPsiqueiaServices/Sources/ManusPsiqueiaServices"
        ),
        .testTarget(
            name: "ManusPsiqueiaTests",
            dependencies: ["ManusPsiqueia"],
            path: "Tests/ManusPsiqueiaTests"
        )
    ]
)
