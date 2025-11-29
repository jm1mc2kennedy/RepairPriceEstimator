// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RepairPriceEstimator",
    platforms: [
        .iOS(.v17), // Latest stable iOS version (iOS 26 not yet available)
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RepairPriceEstimator",
            targets: ["RepairPriceEstimator"])
    ],
    dependencies: [
        // Add SwiftUI testing support
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "RepairPriceEstimator",
            dependencies: [],
            path: "RepairPriceEstimator"
        ),
        .testTarget(
            name: "RepairPriceEstimatorTests",
            dependencies: [
                "RepairPriceEstimator",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "RepairPriceEstimatorTests"
        )
    ],
    swiftLanguageModes: [.v6]
)