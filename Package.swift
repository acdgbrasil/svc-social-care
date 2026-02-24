// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SOCIAL-CARE",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "6.2.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "social-care-s"
        ),
        .testTarget(
            name: "social-care-sTests",
            dependencies: [
                "social-care-s",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)