// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManusPsiqueia",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "manuspsiqueia",
            targets: ["manuspsiqueia"]
        ),
    ],
    targets: [
        .target(
            name: "manuspsiqueia",
            dependencies: [],
            path: "Sources/manuspsiqueia"
        ),
        .testTarget(
            name: "ManusPsiqueiaTests",
            dependencies: ["manuspsiqueia"],
            path: "Tests"
        ),
    ]
)
