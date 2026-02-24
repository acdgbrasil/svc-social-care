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
        .executableTarget(
            name: "social-care-s",
            path: "Sources/social-care-s"
        ),
        .testTarget(
            name: "social-care-sTests",
            dependencies: [
                "social-care-s",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/social-care-sTests"
        ),
    ]
)
