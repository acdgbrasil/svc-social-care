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
        .package(url: "https://github.com/vapor/sql-kit.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
        .package(url: "https://github.com/nats-io/nats.swift.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "social-care-s",
            dependencies: [
                .product(name: "SQLKit", package: "sql-kit"),
                .product(name: "PostgresKit", package: "postgres-kit"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "Nats", package: "nats.swift"),
            ],
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
