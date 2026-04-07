---
title: "Mutation commands must include actorId for audit trail"
scope: "file"
path: ["Sources/social-care-s/Application/**/Command/**/*.swift"]
severity_min: "critical"
languages: ["swift"]
buckets: ["security", "architecture"]
enabled: true
---

## Instructions

Every command that triggers a mutation (create, update, delete) must carry an `actorId: String` property. This is a non-negotiable audit trail requirement — the system must know WHO performed every data change.

The `actorId` flows from:
1. JWT token → `AuthenticatedUser.userId`
2. Controller extracts via `req.extractActorId()`
3. Passed into the command struct
4. Persisted alongside the domain event in the outbox

Flag:
- Command structs conforming to `Command` or `ResultCommand` that perform mutations but lack an `actorId` property
- Note: Query-only commands (read operations) do NOT need actorId

## Examples

### Bad example
```swift
public struct RegisterPatientCommand: ResultCommand {
    public typealias Result = String
    public let personalData: PersonalDataDraft
    public let socialIdentity: SocialIdentityDraft
    // Missing actorId — no audit trail for who registered this patient
}
```

### Good example
```swift
public struct RegisterPatientCommand: ResultCommand {
    public typealias Result = String
    public let personalData: PersonalDataDraft
    public let socialIdentity: SocialIdentityDraft
    public let actorId: String
}
```
