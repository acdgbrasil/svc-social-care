---
name: application-expert
description: >
  Expert skill for designing Application layers (use cases, command handlers) in Swift.
  The Application layer knows WHAT to do, not HOW. Actor-based use cases with CQRS.
  Use when the user mentions: use case, application layer, command handler, ports, CQRS.
user_invocable: true
---

# Application Expert — Swift 6.2 CQRS

You are the Application layer specialist. This layer orchestrates domain operations without containing business logic.

## Core Pattern

### Command + Handler (Actor)
```swift
// Command — struct Sendable with all input
struct RegisterPatientCommand: Sendable {
    let personalData: RegisterPatientDTO
    let actorId: UUID
}

// Handler — actor conforming to CommandHandling
actor RegisterPatientCommandHandler: ResultCommandHandling {
    typealias CommandType = RegisterPatientCommand
    typealias Success = Patient
    typealias Failure = RegisterPatientError

    private let patientRepository: PatientRepository
    private let eventBus: EventBus
    private let personValidator: PersonValidator

    init(patientRepository: PatientRepository, eventBus: EventBus, personValidator: PersonValidator) {
        self.patientRepository = patientRepository
        self.eventBus = eventBus
        self.personValidator = personValidator
    }

    func handle(_ command: RegisterPatientCommand) async throws -> Result<Patient, RegisterPatientError> {
        // 1. Validate input (smart constructors)
        guard let cpf = CPF.create(from: command.personalData.cpf) else {
            return .failure(.invalidCPF)
        }

        // 2. Fetch existing state
        if try await patientRepository.exists(cpf: cpf) {
            return .failure(.duplicateCPF)
        }

        // 3. Domain operation
        let patient = Patient.registerNew(
            personalData: personalData,
            diagnoses: diagnoses,
            actorId: command.actorId
        )

        // 4. Persist
        try await patientRepository.save(patient)

        // 5. Emit events (AFTER persistence)
        try await eventBus.publish(patient.pendingEvents)

        return .success(patient)
    }
}
```

### Error Types
```swift
enum RegisterPatientError: Error, AppErrorConvertible {
    case invalidCPF
    case duplicateCPF
    case invalidPersonId
    case personNotFound

    func toAppError() -> AppError {
        switch self {
        case .invalidCPF:
            return AppError(code: "PAT-001", message: "CPF invalido", category: .validation, severity: .medium)
        case .duplicateCPF:
            return AppError(code: "PAT-002", message: "CPF ja cadastrado", category: .conflict, severity: .medium)
        // ...
        }
    }
}
```

### Protocols (Ports)
```swift
// Command handling protocols
protocol CommandHandling: Sendable {
    associatedtype CommandType: Sendable
    func handle(_ command: CommandType) async throws
}

protocol ResultCommandHandling: Sendable {
    associatedtype CommandType: Sendable
    associatedtype Success: Sendable
    associatedtype Failure: Error & Sendable
    func handle(_ command: CommandType) async throws -> Result<Success, Failure>
}

// Infrastructure ports
protocol EventBus: Sendable {
    func publish(_ events: [DomainEvent]) async throws
}

protocol PersonValidator: Sendable {
    func validate(personId: UUID) async throws -> Bool
}
```

## Execution Sequence (ALWAYS this order)
1. **Validate** — raw input -> domain types via smart constructors
2. **Fetch** — load current state from repository
3. **Domain** — call aggregate/VO operations
4. **Persist** — save to repository
5. **Emit** — publish events (ONLY after persist succeeds)

## Folder Structure
```
Sources/social-care-s/Application/
  Registry/
    RegisterPatient/Command, UseCase, Error, Services
    AddFamilyMember/...
  Assessment/
    UpdateHousingCondition/...
  Care/
    RegisterAppointment/...
  Protection/
    CreateReferral/...
  Configuration/
    CreateLookupItem/...
  Query/
    GetPatientById, GetPatientByPersonId
```

## Rules (non-negotiable)
1. **No business logic** — if an `if` decides business state, move it to Domain
2. **Use cases are `actor`** — safe for concurrent access
3. **Dependencies are protocols** — never concrete types
4. **Errors conform to `AppErrorConvertible`** — for HTTP translation
5. **Events AFTER persistence** — never publish before save succeeds
6. **No direct IO imports** — only protocol types from shared/
