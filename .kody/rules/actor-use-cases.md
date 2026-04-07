---
title: "Use case handlers must be declared as actor"
scope: "file"
path: ["Sources/social-care-s/Application/**/Services/**Handler*.swift"]
severity_min: "high"
languages: ["swift"]
buckets: ["architecture", "security"]
enabled: true
---

## Instructions

All command handlers (use cases) must be declared as `actor` to guarantee thread safety under Swift 6.2 strict concurrency. This project uses `CommandHandling` and `ResultCommandHandling` protocols, both of which require `Actor` conformance.

Flag:
- Handlers declared as `class` or `struct` instead of `actor`
- Handlers not conforming to `CommandHandling<C>` or `ResultCommandHandling<C>`
- Handlers missing dependency injection via `init`

The handler pattern is:
1. Declare as `public actor`
2. Conform to `CommandHandling<C>` or `ResultCommandHandling<C>`
3. Receive dependencies (repositories, event bus) via `init`
4. Implement `handle(_ command: C) async throws` (or `-> C.Result`)

## Examples

### Bad example
```swift
public class RegisterPatientHandler {
    private let repository: any PatientRepository

    func handle(_ command: RegisterPatientCommand) async throws -> String {
        // not an actor — data race risk under concurrent requests
    }
}
```

### Good example
```swift
public actor RegisterPatientCommandHandler: ResultCommandHandling {
    public typealias C = RegisterPatientCommand

    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: RegisterPatientCommand) async throws -> String {
        let patient = try Patient.register(
            personalData: command.personalData,
            socialIdentity: command.socialIdentity
        )
        try await repository.save(patient)
        try await eventBus.publish(patient.uncommittedEvents)
        return patient.id.description
    }
}
```
