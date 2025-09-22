// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManusPsiqueiaUI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ManusPsiqueiaUI",
            targets: ["ManusPsiqueiaUI"]
        ),
    ],
    dependencies: [
        // SwiftUI não precisa de dependências externas
    ],
    targets: [
        .target(
            name: "ManusPsiqueiaUI",
            dependencies: [],
            path: "Sources/ManusPsiqueiaUI"
        ),
        .testTarget(
            name: "ManusPsiqueiaUITests",
            dependencies: ["ManusPsiqueiaUI"],
            path: "Tests/ManusPsiqueiaUITests"
        ),
    ]
)
