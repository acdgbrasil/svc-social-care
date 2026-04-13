# Type-Level Contracts: Patient Discharge

## 1. Domain Layer — New Value Objects

### PatientStatus (enum, Sendable, Codable, Equatable)
```swift
public enum PatientStatus: String, Sendable, Codable, Equatable {
    case active
    case discharged
}
```
File: `Sources/social-care-s/Domain/Registry/ValueObjects/PatientStatus.swift`

### DischargeReason (enum, Sendable, Codable, Equatable)
```swift
public enum DischargeReason: String, Sendable, Codable, Equatable, CaseIterable {
    case caseObjectiveAchieved
    case transferredToAnotherService
    case patientRequestedDischarge
    case lossOfContact
    case relocation
    case death
    case other
}
```
File: `Sources/social-care-s/Domain/Registry/ValueObjects/DischargeReason.swift`

### DischargeInfo (struct, Sendable, Codable, Equatable)
```swift
public struct DischargeInfo: Sendable, Codable, Equatable {
    public let reason: DischargeReason
    public let notes: String?
    public let dischargedAt: TimeStamp
    public let dischargedBy: String

    public init(reason: DischargeReason, notes: String?, dischargedAt: TimeStamp, dischargedBy: String) throws
    // Validation: if reason == .other, notes must be non-nil and non-empty
    // Validation: notes max 1000 chars
}
```
Error enum:
```swift
public enum DischargeInfoError: Error, Sendable, Equatable {
    case notesRequiredWhenReasonIsOther
    case notesExceedMaxLength(Int)
}
```
File: `Sources/social-care-s/Domain/Registry/ValueObjects/DischargeInfo.swift`

## 2. Domain Layer — Aggregate Changes

### Patient struct additions
```swift
// New fields
public internal(set) var status: PatientStatus   // default: .active
public internal(set) var dischargeInfo: DischargeInfo?
```

### Patient.discharge() method
```swift
// In PatientLifecycle.swift extension
public mutating func discharge(reason: DischargeReason, notes: String?, actorId: String, now: TimeStamp = .now) throws
// Pre: status == .active, else throw PatientError.alreadyDischarged
// Creates DischargeInfo, sets status = .discharged
// Records PatientDischargedEvent
```

### Patient.readmit() method
```swift
public mutating func readmit(notes: String?, actorId: String, now: TimeStamp = .now) throws
// Pre: status == .discharged, else throw PatientError.alreadyActive
// Sets status = .active, dischargeInfo = nil
// Records PatientReadmittedEvent
```

### PatientError additions
```swift
// Add to existing PatientError enum
case alreadyDischarged
case alreadyActive
```

## 3. Domain Layer — New Events

### PatientDischargedEvent
```swift
public struct PatientDischargedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let personId: String
    public let actorId: String
    public let reason: String
    public let notes: String?
    public let occurredAt: Date
}
```

### PatientReadmittedEvent
```swift
public struct PatientReadmittedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let personId: String
    public let actorId: String
    public let notes: String?
    public let occurredAt: Date
}
```
File: `Sources/social-care-s/Domain/Registry/Aggregates/Patient/Events/PatientEvents.swift` (append)

## 4. Domain Layer — Repository Changes

### PatientRepository protocol
```swift
// Extend list() signature:
func list(search: String?, status: PatientStatus?, cursor: PatientId?, limit: Int) async throws -> PatientListResult
```

### PatientSummary additions
```swift
// Add to existing PatientSummary struct
public let status: PatientStatus
```

## 5. Application Layer — Commands & Handlers

### DischargePatientCommand
```swift
public struct DischargePatientCommand: Command {
    public let patientId: String
    public let reason: String
    public let notes: String?
    public let actorId: String
}
```
File: `Sources/social-care-s/Application/Registry/DischargePatient/Command/DischargePatientCommand.swift`

### DischargePatientCommandHandler (actor)
```swift
public actor DischargePatientCommandHandler: CommandHandling {
    typealias C = DischargePatientCommand
    init(repository: any PatientRepository, eventBus: any EventBus)
    func handle(_ command: DischargePatientCommand) async throws
    // Sequence: parse → fetch → precondition → domain → persist → publish
}
```
File: `Sources/social-care-s/Application/Registry/DischargePatient/Services/DischargePatientCommandHandler.swift`

### DischargePatientError
```swift
public enum DischargePatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyDischarged(String)
    case invalidReason(String)
    case notesRequiredForOtherReason
    case notesExceedMaxLength(Int)
    case invalidPatientIdFormat(String)
}
```
AppErrorConvertible: bc="SOCIAL", module="social-care/application", codePrefix="DISC"
File: `Sources/social-care-s/Application/Registry/DischargePatient/Error/DischargePatientError.swift`

### ReadmitPatientCommand
```swift
public struct ReadmitPatientCommand: Command {
    public let patientId: String
    public let notes: String?
    public let actorId: String
}
```
File: `Sources/social-care-s/Application/Registry/ReadmitPatient/Command/ReadmitPatientCommand.swift`

### ReadmitPatientCommandHandler (actor)
```swift
public actor ReadmitPatientCommandHandler: CommandHandling {
    typealias C = ReadmitPatientCommand
    init(repository: any PatientRepository, eventBus: any EventBus)
    func handle(_ command: ReadmitPatientCommand) async throws
}
```
File: `Sources/social-care-s/Application/Registry/ReadmitPatient/Services/ReadmitPatientCommandHandler.swift`

### ReadmitPatientError
```swift
public enum ReadmitPatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyActive(String)
    case invalidPatientIdFormat(String)
    case notesExceedMaxLength(Int)
}
```
AppErrorConvertible: bc="SOCIAL", module="social-care/application", codePrefix="READM"
File: `Sources/social-care-s/Application/Registry/ReadmitPatient/Error/ReadmitPatientError.swift`

### ListPatientsQuery changes
```swift
// Add status parameter:
public struct ListPatientsQuery: Query {
    public let search: String?
    public let status: String?   // NEW: "active" | "discharged" | nil (all)
    public let cursor: String?
    public let limit: Int
}
```

## 6. IO Layer — Migration

### 2026_04_12_AddPatientDischarge
```sql
ALTER TABLE patients ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';
ALTER TABLE patients ADD COLUMN discharge_reason VARCHAR(50);
ALTER TABLE patients ADD COLUMN discharge_notes TEXT;
ALTER TABLE patients ADD COLUMN discharged_at TIMESTAMPTZ;
ALTER TABLE patients ADD COLUMN discharged_by VARCHAR(255);
CREATE INDEX idx_patients_status ON patients(status);
```

## 7. IO Layer — HTTP

### Controller routes (add to PatientController)
```swift
let write = patients.grouped(RoleGuardMiddleware("social_worker", "admin"))
write.post(":patientId", "discharge", use: discharge)
write.post(":patientId", "readmit", use: readmit)
```

### DTOs
```swift
struct DischargePatientRequest: Content {
    let reason: String
    let notes: String?
}

struct ReadmitPatientRequest: Content {
    let notes: String?
}
```

### PatientResponse additions
```swift
// Add to PatientResponse:
let status: String           // "active" | "discharged"
let dischargeInfo: DischargeInfoResponse?

struct DischargeInfoResponse: Content {
    let reason: String
    let notes: String?
    let dischargedAt: Date
    let dischargedBy: String
}
```

### PatientSummaryResponse additions
```swift
// Add:
let status: String
```

## 8. ServiceContainer changes
```swift
let dischargePatient: DischargePatientCommandHandler
let readmitPatient: ReadmitPatientCommandHandler
```
