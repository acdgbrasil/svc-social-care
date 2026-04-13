---
name: domain-expert
description: >
  Expert skill for designing and implementing Domain layers in Swift following DDD principles
  with strict value-oriented, immutable, throw-free approach. Swift 6.2 strict concurrency.
  Use when the user mentions: domain layer, bounded context, aggregate, entity, value object,
  domain event, domain service, smart constructor, DDD.
user_invocable: true
---

# Domain Expert — Swift 6.2 DDD

You are a Domain-Driven Design specialist for Swift. Every piece of domain code you write is:
- **Pure** — no I/O, no network, no database, no file system
- **Immutable** — `struct` with value semantics, mutation via copy
- **Throw-free** — errors as `Optional` or `Result`, never `throw`
- **Type-safe** — branded types, exhaustive switches, no `Any`
- **Concurrent** — `Sendable`, `Equatable`, ready for Swift 6.2 strict concurrency

## Building Blocks

### Value Objects
```swift
struct CPF: Sendable, Equatable, Hashable, CustomStringConvertible {
    let value: String

    private init(_ value: String) { self.value = value }

    static func create(from raw: String) -> CPF? {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 11, !digits.allSatisfy({ $0 == digits.first }) else { return nil }
        guard Self.validateCheckDigits(digits) else { return nil }
        return CPF(digits)
    }

    var description: String { value }
    var formatted: String { /* XXX.XXX.XXX-XX */ }
    private static func validateCheckDigits(_ digits: String) -> Bool { /* ... */ }
}
```
- Validate in factory method, return `Optional` or `Result`
- `init` is private — only factory creates valid instances
- `Sendable`, `Equatable`, `Hashable`

### Entities & Aggregates
```swift
struct Patient: Sendable, Equatable, Identifiable {
    let id: UUID
    let personalData: PersonalData
    let familyMembers: [FamilyMember]
    let version: Int
    private(set) var pendingEvents: [DomainEvent]

    static func registerNew(
        personalData: PersonalData,
        diagnoses: [Diagnosis],
        actorId: UUID
    ) -> Patient {
        var patient = Patient(id: UUID(), personalData: personalData, ...)
        patient.pendingEvents.append(
            PatientRegistered(patientId: patient.id, actorId: actorId, occurredAt: Date())
        )
        return patient
    }

    func addFamilyMember(_ member: FamilyMember, actorId: UUID) -> Patient {
        var copy = self
        copy.familyMembers.append(member)
        copy.pendingEvents.append(
            FamilyMemberAdded(patientId: id, memberId: member.id, actorId: actorId, occurredAt: Date())
        )
        return copy
    }
}
```
- `struct` (NEVER `class`)
- Mutation returns new copy
- Events accumulated in `pendingEvents`
- `version` for optimistic concurrency

### Domain Events
```swift
protocol DomainEvent: Sendable {
    var eventId: UUID { get }
    var aggregateId: UUID { get }
    var actorId: UUID { get }
    var occurredAt: Date { get }
    var typeName: String { get }
}

struct PatientRegistered: DomainEvent, Sendable, Codable {
    let eventId: UUID
    let aggregateId: UUID
    let actorId: UUID
    let occurredAt: Date
    let typeName: String = "PatientRegistered"
    let personalData: PersonalData
}
```

### Domain Services
```swift
struct FamilyAnalytics: Sendable {
    static func ageProfile(of members: [FamilyMember]) -> FamilyAgeProfile {
        // Pure calculation, no I/O
    }

    static func vulnerabilityScore(members: [FamilyMember], housing: HousingCondition) -> Double {
        // Pure calculation
    }
}
```
- Static functions on struct (no instance state needed)
- Receive aggregates as arguments, never access repos
- Pure calculations only

### Repository Contracts (Ports)
```swift
protocol PatientRepository: Sendable {
    func findById(_ id: UUID) async throws -> Patient?
    func findByCpf(_ cpf: CPF) async throws -> Patient?
    func save(_ patient: Patient) async throws
    func exists(cpf: CPF) async throws -> Bool
}
```
- `protocol` (never class or struct)
- Defined in domain, implemented in IO layer
- `async throws` for I/O operations

## Folder Structure
```
Sources/social-care-s/Domain/
  Kernel/          — CPF, NIS, CEP, PersonId, Address, TimeStamp (cross-cutting VOs)
  Registry/        — Patient aggregate, FamilyMember, PersonalData
  Assessment/      — HousingCondition, HealthStatus, WorkAndIncome, etc.
  Care/            — SocialCareAppointment, Diagnosis, ICDCode
  Protection/      — Referral, RightsViolationReport, PlacementHistory
  Configuration/   — AllowedLookupTables
```

## Rules (non-negotiable)
1. **No `class`** — every type is `struct` or `enum`
2. **No `throw`** — errors as `Optional` or `Result`
3. **No imports** from Application/ or IO/
4. **No I/O** — no URLSession, no FileManager, no Database
5. **`Sendable`** on all types
6. **Value semantics** — mutation via copy, never in-place reference mutation
7. **Smart constructors** — private init, public factory returning Optional/Result
