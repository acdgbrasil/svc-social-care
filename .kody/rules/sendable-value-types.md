---
title: "Value Objects and Commands must be Sendable structs"
scope: "file"
path: ["Sources/social-care-s/Domain/**/*.swift", "Sources/social-care-s/Application/**/Command/**/*.swift"]
severity_min: "high"
languages: ["swift"]
buckets: ["architecture", "style-conventions"]
enabled: true
---

## Instructions

Swift 6.2 strict concurrency requires all Value Objects and Commands to be safe for concurrent access.

**Value Objects (Domain layer):**
- Must be declared as `public struct` (never `class`)
- Must conform to `Sendable`
- Typically also conform to `Codable, Hashable, Equatable, CustomStringConvertible`
- Must be immutable (all properties `let`, no `var`)
- Validation must happen in `init(...) throws`

**Commands (Application layer):**
- Must be declared as `public struct`
- Must conform to `Command` or `ResultCommand` protocol (both inherit `Sendable`)
- All properties must be `let`
- Mutation commands must include an `actorId: String` property

Flag:
- VOs or Commands declared as `class`
- Missing `Sendable` conformance
- Mutable properties (`var`) on VOs or Commands
- Commands implementing mutations without `actorId`

## Examples

### Bad example
```swift
public class RegisterPatientCommand {
    var patientName: String
    var cpf: String

    init(patientName: String, cpf: String) {
        self.patientName = patientName
        self.cpf = cpf
    }
}
```

### Good example
```swift
public struct RegisterPatientCommand: ResultCommand {
    public typealias Result = String

    public let personalData: PersonalDataDraft
    public let socialIdentity: SocialIdentityDraft
    public let actorId: String

    public init(personalData: PersonalDataDraft, socialIdentity: SocialIdentityDraft, actorId: String) {
        self.personalData = personalData
        self.socialIdentity = socialIdentity
        self.actorId = actorId
    }
}
```
