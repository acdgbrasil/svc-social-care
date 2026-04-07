---
title: "Domain layer must not import external frameworks"
scope: "file"
path: ["Sources/social-care-s/Domain/**/*.swift"]
severity_min: "critical"
languages: ["swift"]
buckets: ["architecture"]
enabled: true
---

## Instructions

The Domain layer follows DDD strictly and must have **zero external dependencies**. Only Swift standard library and Foundation are allowed.

Flag any import of:
- **Vapor** or any Vapor module (e.g., `import Vapor`)
- **SQLKit**, **PostgresKit**, **FluentKit**, or any persistence framework
- **JWT**, **JWTKit**, or any auth framework
- **NIO**, **NIOCore**, **NIOHTTP1**, or any SwiftNIO module
- Any module from the `IO/` or `Application/` layers

Allowed imports:
- `import Foundation`
- Other Domain modules within the same layer (cross-context references)

This is a non-negotiable architectural boundary. The Domain layer defines business rules and must remain portable and testable without infrastructure.

## Examples

### Bad example
```swift
import Foundation
import Vapor
import SQLKit

public struct PatientId: Codable, Sendable, Hashable {
    // ...
}
```

### Good example
```swift
import Foundation

public struct PatientId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    private let value: String

    public init(_ rawValue: String) throws {
        guard let _ = UUID(uuidString: rawValue) else {
            throw PatientIdError.invalidFormat(rawValue)
        }
        self.value = rawValue
    }
}
```
