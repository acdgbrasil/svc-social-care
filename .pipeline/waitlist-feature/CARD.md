# CARD: Lista de Espera (Waitlist) — Ciclo de Vida Completo do Paciente

> **Serviço:** social-care (Swift 6.2 / Vapor 4)
> **Bounded Context:** Registry
> **Prioridade:** Alta
> **Tipo:** Feature (novo ciclo de vida)

---

## 1. Contexto e Motivação

### O que existe hoje

O agregado `Patient` possui um campo `status: PatientStatus` com dois estados:

```swift
// Domain/Registry/ValueObjects/PatientStatus.swift
public enum PatientStatus: String, Sendable, Codable, Equatable {
    case active
    case discharged
}
```

Quando um paciente é registrado (`RegisterPatientCommand`), ele entra **imediatamente como `active`**. Isso significa que o registro e a admissão para acompanhamento são um único ato.

### O problema

A ONG tem capacidade limitada de atendimento. Nem toda pessoa registrada pode ser atendida imediatamente. Hoje não existe forma de:

1. Registrar alguém que ainda **não está sendo atendido** mas pode vir a ser
2. Manter uma **fila de espera** organizada
3. Saber quantas pessoas aguardam e há quanto tempo
4. Quando um paciente é desligado, **admitir o próximo da fila** de forma consciente

### A decisão de produto

**Todo paciente novo entra obrigatoriamente como `waitlisted` (em espera).** A admissão para acompanhamento ativo é um ato separado e consciente do assistente social. Isso separa duas decisões profissionais distintas:

- **Registrar** = "essa pessoa existe no sistema e precisa de acompanhamento"
- **Admitir** = "agora vamos atender essa pessoa"

---

## 2. Por que o People Context NÃO muda

O People Context gerencia **identidade**: "essa pessoa existe e tem a role X no sistema Y". O campo `active` da `PersonSystemRole` responde à pergunta: **"essa pessoa é paciente do Social Care, sim ou não?"**

A fila de espera é um **detalhe interno do processo de atendimento** do Social Care. Do ponto de vista do People Context:

- Uma pessoa **na fila de espera** do Social Care **é paciente** → role ativa
- Uma pessoa **em atendimento ativo** no Social Care **é paciente** → role ativa
- Uma pessoa **desligada** do Social Care **não é mais paciente** → role desativada

O People Context não sabe e não precisa saber em que estágio do atendimento a pessoa está. Ele só sabe se a role existe e está ativa.

### Tabela de interação entre serviços

| Momento no Social Care | PatientStatus | People Context: role active? | Chamada ao People Context |
|------------------------|---------------|------------------------------|---------------------------|
| Registro (novo) | `waitlisted` | `true` | Assign role `(social-care, patient)` — **já acontece hoje no RegisterPatient** |
| Admissão (sai da fila) | `active` | `true` (sem mudança) | **Nenhuma** |
| Desligamento | `discharged` | `false` | `PUT /people/{personId}/roles/{roleId}/deactivate` |
| Readmissão | `active` | `true` | `PUT /people/{personId}/roles/{roleId}/reactivate` |
| Desistência da fila | `discharged` | `false` | `PUT /people/{personId}/roles/{roleId}/deactivate` |

**Conclusão:** Zero mudanças no People Context. Zero novos endpoints. Zero novos eventos. Tudo é interno ao Social Care.

---

## 3. Novo Ciclo de Vida (State Machine)

```
                    ┌──────────────┐
   Registro ──────▶ │  waitlisted  │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │ admit()    │            │ withdraw()
              ▼            │            ▼
       ┌──────────┐        │     ┌─────────────┐
       │  active   │◀──────┘     │  discharged  │
       └────┬─────┘              └──────▲───────┘
            │ discharge()               │
            └───────────────────────────┘
            │                           ▲
            └───── readmit() ───────────┘
```

### Transições válidas

| De | Para | Método | Quem pode |
|---|---|---|---|
| `waitlisted` | `active` | `patient.admit(actorId:)` | `social_worker`, `admin` |
| `waitlisted` | `discharged` | `patient.withdraw(reason:, notes:, actorId:)` | `social_worker`, `admin` |
| `active` | `discharged` | `patient.discharge(reason:, notes:, actorId:)` | `social_worker`, `admin` — **já existe** |
| `discharged` | `active` | `patient.readmit(notes:, actorId:)` | `social_worker`, `admin` — **já existe** |

### Transições inválidas (devem retornar erro)

| Tentativa | Erro |
|---|---|
| `active` → `admit()` | `PatientError.alreadyActive` (PAT-013) — **já existe** |
| `discharged` → `admit()` | `PatientError.cannotAdmitDischarged` — **novo** |
| `waitlisted` → `discharge()` | `PatientError.cannotDischargeWaitlisted` — **novo** (usar `withdraw` ao invés) |
| `waitlisted` → `readmit()` | `PatientError.cannotReadmitWaitlisted` — **novo** (usar `admit` ao invés) |
| `discharged` → `withdraw()` | `PatientError.alreadyDischarged` (PAT-012) — **já existe** |

---

## 4. Mudanças por Camada

### 4.1 Domain

#### 4.1.1 Alterar `PatientStatus` enum

**Arquivo:** `Sources/social-care-s/Domain/Registry/ValueObjects/PatientStatus.swift`

```swift
public enum PatientStatus: String, Sendable, Codable, Equatable {
    case waitlisted    // novo
    case active
    case discharged
}
```

#### 4.1.2 Novos erros em `PatientErrors.swift`

**Arquivo:** `Sources/social-care-s/Domain/Registry/Aggregates/Patient/Errors/PatientErrors.swift`

Adicionar ao enum `PatientError`:

```swift
// Versão 2.2 - Lista de Espera
case cannotAdmitDischarged
case cannotDischargeWaitlisted
case cannotReadmitWaitlisted
case alreadyWaitlisted
```

Adicionar ao `AppErrorConvertible`:

| Case | Código | HTTP | Category | Mensagem |
|------|--------|------|----------|----------|
| `cannotAdmitDischarged` | PAT-014 | 409 | conflict | "Paciente desligado não pode ser admitido diretamente. Use readmit primeiro." |
| `cannotDischargeWaitlisted` | PAT-015 | 409 | conflict | "Paciente em lista de espera não pode ser desligado. Use withdraw." |
| `cannotReadmitWaitlisted` | PAT-016 | 409 | conflict | "Paciente em lista de espera não pode ser readmitido. Use admit." |
| `alreadyWaitlisted` | PAT-017 | 409 | conflict | "O paciente já está na lista de espera." |

#### 4.1.3 Novos eventos em `PatientEvents.swift`

**Arquivo:** `Sources/social-care-s/Domain/Registry/Aggregates/Patient/Events/PatientEvents.swift`

Seguir o padrão exato dos eventos existentes (`DomainEvent, Codable`, UUID `id` auto-generated):

```swift
// MARK: - Waitlist Events

public struct PatientAdmittedEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let personId: String
    public let actorId: String
    public let occurredAt: Date

    public init(patientId: String, personId: String, actorId: String, occurredAt: Date) {
        self.id = UUID(); self.patientId = patientId; self.personId = personId
        self.actorId = actorId; self.occurredAt = occurredAt
    }
}

public struct PatientWithdrawnFromWaitlistEvent: DomainEvent, Codable {
    public let id: UUID
    public let patientId: String
    public let personId: String
    public let actorId: String
    public let reason: String
    public let notes: String?
    public let occurredAt: Date

    public init(patientId: String, personId: String, actorId: String, reason: String, notes: String?, occurredAt: Date) {
        self.id = UUID(); self.patientId = patientId; self.personId = personId
        self.actorId = actorId; self.reason = reason; self.notes = notes; self.occurredAt = occurredAt
    }
}
```

#### 4.1.4 Novo VO: `WithdrawReason`

**Novo arquivo:** `Sources/social-care-s/Domain/Registry/ValueObjects/WithdrawReason.swift`

```swift
public enum WithdrawReason: String, Sendable, Codable, Equatable, CaseIterable {
    case patientDeclined          // paciente/família recusou o atendimento
    case noResponse               // não respondeu às tentativas de contato
    case duplicateRecord          // registro duplicado
    case ineligible               // não atende aos critérios
    case transferredBeforeAdmit   // transferido para outro serviço antes de ser admitido
    case other                    // outro motivo (notes obrigatório)
}
```

#### 4.1.5 Novo VO: `WithdrawInfo`

**Novo arquivo:** `Sources/social-care-s/Domain/Registry/ValueObjects/WithdrawInfo.swift`

Seguir o padrão exato de `DischargeInfo.swift`:

```swift
public struct WithdrawInfo: Sendable, Codable, Equatable {
    public let reason: WithdrawReason
    public let notes: String?
    public let withdrawnAt: TimeStamp
    public let withdrawnBy: String

    public init(reason: WithdrawReason, notes: String?, withdrawnAt: TimeStamp, withdrawnBy: String) throws {
        if reason == .other {
            guard let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WithdrawInfoError.notesRequiredWhenReasonIsOther
            }
        }
        if let notes, notes.count > 1000 {
            throw WithdrawInfoError.notesExceedMaxLength(notes.count)
        }
        self.reason = reason
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.withdrawnAt = withdrawnAt
        self.withdrawnBy = withdrawnBy
    }
}

public enum WithdrawInfoError: Error, Sendable, Equatable {
    case notesRequiredWhenReasonIsOther
    case notesExceedMaxLength(Int)
}
```

Com `AppErrorConvertible` (prefixo `WI`):

| Case | Código | HTTP |
|------|--------|------|
| `notesRequiredWhenReasonIsOther` | WI-001 | 422 |
| `notesExceedMaxLength` | WI-002 | 422 |

#### 4.1.6 Alterar agregado `Patient`

**Arquivo:** `Sources/social-care-s/Domain/Registry/Aggregates/Patient/Patient.swift`

Adicionar campo:

```swift
/// Informações da desistência/retirada da fila, preenchidas quando saiu da fila sem ser admitido.
public internal(set) var withdrawInfo: WithdrawInfo?
```

**Arquivo:** `Sources/social-care-s/Domain/Registry/Aggregates/Patient/PatientLifecycle.swift`

**Mudança 1 — `init(...)` agora cria com `.waitlisted`:**

Na linha onde está:
```swift
// (dentro do init, o status default já é .active no Patient struct)
```

Mudar o default do campo `status` no `Patient.swift` de `.active` para `.waitlisted`.

**Mudança 2 — Adicionar `admit()` method:**

```swift
/// Admite um paciente da lista de espera para acompanhamento ativo.
///
/// - Throws: `PatientError.alreadyActive` se já está ativo.
/// - Throws: `PatientError.cannotAdmitDischarged` se está desligado.
public mutating func admit(actorId: String, now: TimeStamp = .now) throws {
    switch status {
    case .active:
        throw PatientError.alreadyActive
    case .discharged:
        throw PatientError.cannotAdmitDischarged
    case .waitlisted:
        self.status = .active
        self.recordEvent(PatientAdmittedEvent(
            patientId: id.description,
            personId: personId.description,
            actorId: actorId,
            occurredAt: now.date
        ))
    }
}
```

**Mudança 3 — Adicionar `withdraw()` method:**

```swift
/// Remove o paciente da lista de espera sem admiti-lo (desistência, inelegibilidade, etc).
///
/// - Throws: `PatientError.alreadyDischarged` se já está desligado.
/// - Throws: `PatientError.alreadyActive` se está ativo (usar discharge).
/// - Throws: `WithdrawInfoError` se a validação falhar.
public mutating func withdraw(reason: WithdrawReason, notes: String?, actorId: String, now: TimeStamp = .now) throws {
    switch status {
    case .discharged:
        throw PatientError.alreadyDischarged
    case .active:
        throw PatientError.cannotDischargeWaitlisted // redirecionar para discharge
    case .waitlisted:
        let info = try WithdrawInfo(reason: reason, notes: notes, withdrawnAt: now, withdrawnBy: actorId)
        self.status = .discharged
        self.withdrawInfo = info
        self.recordEvent(PatientWithdrawnFromWaitlistEvent(
            patientId: id.description,
            personId: personId.description,
            actorId: actorId,
            reason: reason.rawValue,
            notes: notes,
            occurredAt: now.date
        ))
    }
}
```

**Mudança 4 — Proteger `discharge()` contra waitlisted:**

No método `discharge()` existente (linha 128-143 de PatientLifecycle.swift), mudar o guard:

```swift
// ANTES:
guard status == .active else {
    throw PatientError.alreadyDischarged
}

// DEPOIS:
switch status {
case .active:
    break // ok, pode desligar
case .discharged:
    throw PatientError.alreadyDischarged
case .waitlisted:
    throw PatientError.cannotDischargeWaitlisted
}
```

**Mudança 5 — Proteger `readmit()` contra waitlisted:**

No método `readmit()` existente (linha 149-165 de PatientLifecycle.swift), mudar o guard:

```swift
// ANTES:
guard status == .discharged else {
    throw PatientError.alreadyActive
}

// DEPOIS:
switch status {
case .discharged:
    break // ok, pode readmitir
case .active:
    throw PatientError.alreadyActive
case .waitlisted:
    throw PatientError.cannotReadmitWaitlisted
}
```

**Mudança 6 — `reconstitute()` recebe `withdrawInfo`:**

Adicionar parâmetro `withdrawInfo: WithdrawInfo? = nil` no `reconstitute()` e atribuir no body.

---

### 4.2 Application

#### 4.2.1 Novo Use Case: `AdmitPatient`

**Diretório:** `Sources/social-care-s/Application/Registry/AdmitPatient/`

Estrutura (seguir padrão exato de `DischargePatient/`):

```
AdmitPatient/
  Command/AdmitPatientCommand.swift
  UseCase/AdmitPatientUseCase.swift
  Services/AdmitPatientCommandHandler.swift
  Error/AdmitPatientError.swift
```

**AdmitPatientCommand.swift:**

```swift
public struct AdmitPatientCommand: Command {
    public let patientId: String
    public let actorId: String

    public init(patientId: String, actorId: String) {
        self.patientId = patientId
        self.actorId = actorId
    }
}
```

**AdmitPatientUseCase.swift:**

```swift
public protocol AdmitPatientUseCase: Sendable {
    func handle(_ command: AdmitPatientCommand) async throws
}
```

**AdmitPatientError.swift:**

```swift
public enum AdmitPatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyActive(String)
    case cannotAdmitDischarged(String)
    case invalidPatientIdFormat(String)
}
```

Com `AppErrorConvertible` (prefixo `ADM`):

| Case | Código | HTTP | Category |
|------|--------|------|----------|
| `patientNotFound` | ADM-001 | 404 | domainRuleViolation |
| `alreadyActive` | ADM-002 | 409 | conflict |
| `cannotAdmitDischarged` | ADM-003 | 409 | conflict |
| `invalidPatientIdFormat` | ADM-004 | 400 | dataConsistencyIncident |

**AdmitPatientCommandHandler.swift:**

Seguir o padrão exato de `DischargePatientCommandHandler`:

```swift
public actor AdmitPatientCommandHandler: AdmitPatientUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: AdmitPatientCommand) async throws {
        do {
            // 1. Parse
            let patientId = try PatientId(command.patientId)

            // 2. Fetch
            guard var patient = try await repository.find(byId: patientId) else {
                throw AdmitPatientError.patientNotFound(command.patientId)
            }

            // 3. Domain
            try patient.admit(actorId: command.actorId)

            // 4. Persist
            try await repository.save(patient)

            // 5. Publish events
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
```

`mapError` segue o padrão dos outros handlers: converte `PatientError` → `AdmitPatientError`.

#### 4.2.2 Novo Use Case: `WithdrawFromWaitlist`

**Diretório:** `Sources/social-care-s/Application/Registry/WithdrawFromWaitlist/`

Estrutura idêntica ao `AdmitPatient/`.

**WithdrawFromWaitlistCommand.swift:**

```swift
public struct WithdrawFromWaitlistCommand: Command {
    public let patientId: String
    public let reason: String
    public let notes: String?
    public let actorId: String

    public init(patientId: String, reason: String, notes: String?, actorId: String) {
        self.patientId = patientId
        self.reason = reason
        self.notes = notes
        self.actorId = actorId
    }
}
```

**WithdrawFromWaitlistError.swift** (prefixo `WDR`):

| Case | Código | HTTP | Category |
|------|--------|------|----------|
| `patientNotFound` | WDR-001 | 404 | domainRuleViolation |
| `alreadyDischarged` | WDR-002 | 409 | conflict |
| `patientIsActive` | WDR-003 | 409 | conflict |
| `invalidReason` | WDR-004 | 400 | domainRuleViolation |
| `notesRequiredForOtherReason` | WDR-005 | 400 | domainRuleViolation |
| `notesExceedMaxLength` | WDR-006 | 400 | domainRuleViolation |
| `invalidPatientIdFormat` | WDR-007 | 400 | dataConsistencyIncident |

**WithdrawFromWaitlistCommandHandler.swift:**

Segue o padrão de `DischargePatientCommandHandler` — parse reason, fetch patient, domain logic, persist, publish.

#### 4.2.3 Alterar `RegisterPatientCommandHandler`

**Nenhuma mudança necessária.** O handler chama `Patient.init(...)` que agora cria com `.waitlisted` por default. O handler não precisa saber disso — é responsabilidade do domínio.

---

### 4.3 IO — HTTP

#### 4.3.1 Novos endpoints no `PatientController`

**Arquivo:** `Sources/social-care-s/IO/HTTP/Controllers/PatientController.swift`

No `boot(routes:)`, dentro do grupo `lifecycle` (que já tem `discharge` e `readmit`):

```swift
let lifecycle = patients.grouped(RoleGuardMiddleware("social_worker", "admin"))
lifecycle.post(":patientId", "discharge", use: discharge)    // já existe
lifecycle.post(":patientId", "readmit", use: readmit)        // já existe
lifecycle.post(":patientId", "admit", use: admit)             // NOVO
lifecycle.post(":patientId", "withdraw", use: withdraw)       // NOVO
```

**Novos métodos no controller:**

```swift
@Sendable
private func admit(req: Request) async throws -> HTTPStatus {
    let actorId = try req.extractActorId()
    let patientId = try req.parameters.require("patientId")
    let command = AdmitPatientCommand(patientId: patientId, actorId: actorId)
    try await req.services.admitPatient.handle(command)
    return .noContent
}

@Sendable
private func withdraw(req: Request) async throws -> HTTPStatus {
    let actorId = try req.extractActorId()
    let patientId = try req.parameters.require("patientId")
    let body = try req.content.decode(WithdrawPatientRequest.self)
    let command = WithdrawFromWaitlistCommand(
        patientId: patientId,
        reason: body.reason,
        notes: body.notes,
        actorId: actorId
    )
    try await req.services.withdrawFromWaitlist.handle(command)
    return .noContent
}
```

#### 4.3.2 Novos Request DTOs

**Arquivo:** `Sources/social-care-s/IO/HTTP/DTOs/RequestDTOs.swift`

```swift
struct WithdrawPatientRequest: Content {
    let reason: String
    let notes: String?
}
```

O `admit` **não tem body** — é só o patientId no path e actorId no header.

#### 4.3.3 Registrar no `ServiceContainer`

**Arquivo:** `Sources/social-care-s/IO/HTTP/Bootstrap/ServiceContainer.swift`

Adicionar:

```swift
let admitPatient: AdmitPatientCommandHandler
let withdrawFromWaitlist: WithdrawFromWaitlistCommandHandler
```

No `init(db:personValidator:)`:

```swift
self.admitPatient = AdmitPatientCommandHandler(
    repository: repository, eventBus: eventBus
)
self.withdrawFromWaitlist = WithdrawFromWaitlistCommandHandler(
    repository: repository, eventBus: eventBus
)
```

---

### 4.4 IO — Persistence

#### 4.4.1 Nova migration

**Novo arquivo:** `Sources/social-care-s/IO/Persistence/SQLKit/Migrations/2026_04_12_AddWaitlistSupport.swift`

```sql
-- A coluna `status` já existe (migration AddPatientDischarge).
-- O DEFAULT atual é 'active'. Precisamos:
-- 1. Mudar o DEFAULT para 'waitlisted' (novos pacientes entram na fila)
-- 2. Adicionar colunas de withdraw info
-- 3. NÃO alterar pacientes existentes (eles já foram admitidos)

ALTER TABLE patients
    ALTER COLUMN status SET DEFAULT 'waitlisted';

ALTER TABLE patients
    ADD COLUMN withdraw_reason VARCHAR(50),
    ADD COLUMN withdraw_notes TEXT,
    ADD COLUMN withdrawn_at TIMESTAMPTZ,
    ADD COLUMN withdrawn_by VARCHAR(255);
```

**Revert:**

```sql
ALTER TABLE patients
    ALTER COLUMN status SET DEFAULT 'active';

ALTER TABLE patients
    DROP COLUMN IF EXISTS withdraw_reason,
    DROP COLUMN IF EXISTS withdraw_notes,
    DROP COLUMN IF EXISTS withdrawn_at,
    DROP COLUMN IF EXISTS withdrawn_by;
```

Registrar a migration em `configure.swift` na lista de migrations.

#### 4.4.2 Alterar `PatientDatabaseModels.swift`

Adicionar ao `PatientModel`:

```swift
let withdraw_reason: String?
let withdraw_notes: String?
let withdrawn_at: Date?
let withdrawn_by: String?
```

#### 4.4.3 Alterar `PatientDatabaseMapper.swift`

**Domain → Database** (`toDatabase`): Mapear `patient.withdrawInfo` para as novas colunas.

**Database → Domain** (`toDomain`): Reconstruir `WithdrawInfo` seguindo o padrão exato de `reconstructDischargeInfo`:

```swift
static func reconstructWithdrawInfo(from p: PatientModel) throws -> WithdrawInfo? {
    guard let reasonRaw = p.withdraw_reason,
          let reason = WithdrawReason(rawValue: reasonRaw),
          let withdrawnAt = p.withdrawn_at,
          let withdrawnBy = p.withdrawn_by else { return nil }

    return try WithdrawInfo(
        reason: reason,
        notes: p.withdraw_notes,
        withdrawnAt: try TimeStamp(withdrawnAt),
        withdrawnBy: withdrawnBy
    )
}
```

Passar `withdrawInfo` para `Patient.reconstitute(...)`.

#### 4.4.4 Alterar query de listagem

O `GET /patients?status=` já aceita o parâmetro `status` (vide `PatientController.list`). O `ListPatientsQuery` já passa isso para o repository. O `SQLKitPatientRepository` precisa aceitar `"waitlisted"` como valor válido no `WHERE status = $1` — o que já acontece automaticamente porque faz `WHERE status = :status` com o raw value do enum. **Nenhuma mudança na query**, desde que o `PatientStatus` enum já tenha o case `waitlisted`.

---

## 5. Endpoints — Resumo HTTP

| Método | Path | Body | Roles | Response | Descrição |
|--------|------|------|-------|----------|-----------|
| `POST` | `/api/v1/patients` | RegisterPatientRequest | `social_worker` | 201 + ID | Registra paciente (entra como `waitlisted`) — **já existe, sem mudança** |
| `POST` | `/api/v1/patients/:patientId/admit` | (vazio) | `social_worker`, `admin` | 204 | **NOVO** — Admite da fila para acompanhamento |
| `POST` | `/api/v1/patients/:patientId/withdraw` | `{ reason, notes? }` | `social_worker`, `admin` | 204 | **NOVO** — Remove da fila sem admitir |
| `POST` | `/api/v1/patients/:patientId/discharge` | `{ reason, notes? }` | `social_worker`, `admin` | 204 | Desliga paciente ativo — **já existe** |
| `POST` | `/api/v1/patients/:patientId/readmit` | `{ notes? }` | `social_worker`, `admin` | 204 | Readmite paciente desligado — **já existe** |
| `GET` | `/api/v1/patients?status=waitlisted` | — | `social_worker`, `owner`, `admin` | 200 | Lista apenas pacientes na fila — **já funciona** |

---

## 6. Catálogo de Erros Completo

### Novos erros (esta feature)

| Código | HTTP | Quando |
|--------|------|--------|
| PAT-014 | 409 | `admit()` em paciente `discharged` |
| PAT-015 | 409 | `discharge()` em paciente `waitlisted` |
| PAT-016 | 409 | `readmit()` em paciente `waitlisted` |
| PAT-017 | 409 | `admit()` em paciente já `waitlisted` (se re-registrar) |
| ADM-001 | 404 | Paciente não encontrado (admit) |
| ADM-002 | 409 | Paciente já ativo (admit) |
| ADM-003 | 409 | Paciente desligado, não pode admitir direto (admit) |
| ADM-004 | 400 | PatientId formato inválido (admit) |
| WDR-001 | 404 | Paciente não encontrado (withdraw) |
| WDR-002 | 409 | Paciente já desligado (withdraw) |
| WDR-003 | 409 | Paciente ativo, usar discharge (withdraw) |
| WDR-004 | 400 | Motivo de withdraw inválido |
| WDR-005 | 400 | Notes obrigatório quando reason=other |
| WDR-006 | 400 | Notes > 1000 chars |
| WDR-007 | 400 | PatientId formato inválido (withdraw) |
| WI-001 | 422 | WithdrawInfo: notes obrigatório para reason=other |
| WI-002 | 422 | WithdrawInfo: notes > 1000 chars |

### Erros existentes reutilizados

| Código | HTTP | Quando |
|--------|------|--------|
| PAT-012 | 409 | `discharge()` em paciente já `discharged` |
| PAT-013 | 409 | `readmit()` em paciente já `active` |

---

## 7. Eventos de Domínio

### Novos

| Evento | Subject NATS | Campos |
|--------|--------------|--------|
| `PatientAdmittedEvent` | `social-care.events.PatientAdmittedEvent` | id, patientId, personId, actorId, occurredAt |
| `PatientWithdrawnFromWaitlistEvent` | `social-care.events.PatientWithdrawnFromWaitlistEvent` | id, patientId, personId, actorId, reason, notes, occurredAt |

### Existentes (não mudar)

| Evento | Quando |
|--------|--------|
| `PatientCreatedEvent` | RegisterPatient (agora cria como waitlisted) |
| `PatientDischargedEvent` | Discharge (active → discharged) |
| `PatientReadmittedEvent` | Readmit (discharged → active) |

---

## 8. Compatibilidade com Dados Existentes

- **Pacientes já cadastrados** permanecem como `active` — a migration **não** altera dados existentes
- **A migration muda apenas o DEFAULT** da coluna `status` de `'active'` para `'waitlisted'`
- **Testes existentes** de `RegisterPatient` vão quebrar porque agora o status inicial é `waitlisted` ao invés de `active` — ajustar assertions
- **Testes existentes** de `discharge()` e `readmit()` continuam passando — esses métodos já operam sobre `active` e `discharged`

---

## 9. Novos Arquivos (checklist)

```
Sources/social-care-s/
├── Domain/Registry/ValueObjects/
│   ├── WithdrawReason.swift          ← NOVO
│   └── WithdrawInfo.swift            ← NOVO
├── Application/Registry/
│   ├── AdmitPatient/
│   │   ├── Command/AdmitPatientCommand.swift        ← NOVO
│   │   ├── UseCase/AdmitPatientUseCase.swift        ← NOVO
│   │   ├── Services/AdmitPatientCommandHandler.swift ← NOVO
│   │   └── Error/AdmitPatientError.swift            ← NOVO
│   └── WithdrawFromWaitlist/
│       ├── Command/WithdrawFromWaitlistCommand.swift        ← NOVO
│       ├── UseCase/WithdrawFromWaitlistUseCase.swift        ← NOVO
│       ├── Services/WithdrawFromWaitlistCommandHandler.swift ← NOVO
│       └── Error/WithdrawFromWaitlistError.swift            ← NOVO
└── IO/Persistence/SQLKit/Migrations/
    └── 2026_04_12_AddWaitlistSupport.swift  ← NOVO
```

## 10. Arquivos Modificados (checklist)

```
Sources/social-care-s/
├── Domain/Registry/
│   ├── ValueObjects/PatientStatus.swift              ← adicionar .waitlisted
│   ├── Aggregates/Patient/Patient.swift              ← adicionar withdrawInfo field, mudar default status
│   ├── Aggregates/Patient/PatientLifecycle.swift     ← admit(), withdraw(), proteger discharge/readmit
│   ├── Aggregates/Patient/Errors/PatientErrors.swift ← 4 novos cases + AppError mapping
│   └── Aggregates/Patient/Events/PatientEvents.swift ← 2 novos event structs
├── IO/HTTP/
│   ├── Controllers/PatientController.swift           ← admit + withdraw routes/handlers
│   ├── DTOs/RequestDTOs.swift                        ← WithdrawPatientRequest
│   └── Bootstrap/ServiceContainer.swift              ← registrar 2 novos handlers
└── IO/Persistence/SQLKit/
    ├── Mappers/PatientDatabaseMapper.swift           ← withdrawInfo mapping
    ├── Mappers/PatientDatabaseModels.swift           ← 4 novas colunas no model
    └── Bootstrap/configure.swift                     ← registrar nova migration
```

---

## 11. Testes Necessários

### Domain

| Teste | Verifica |
|-------|----------|
| `testAdmitFromWaitlisted` | `waitlisted → active`, evento `PatientAdmittedEvent` emitido |
| `testAdmitAlreadyActive` | throws `PatientError.alreadyActive` |
| `testAdmitDischarged` | throws `PatientError.cannotAdmitDischarged` |
| `testWithdrawFromWaitlisted` | `waitlisted → discharged`, evento emitido, `withdrawInfo` preenchido |
| `testWithdrawAlreadyDischarged` | throws `PatientError.alreadyDischarged` |
| `testWithdrawActivePatient` | throws erro (usar discharge, não withdraw) |
| `testWithdrawOtherReasonRequiresNotes` | throws `WithdrawInfoError.notesRequiredWhenReasonIsOther` |
| `testWithdrawNotesMaxLength` | throws `WithdrawInfoError.notesExceedMaxLength` |
| `testDischargeWaitlistedThrows` | `discharge()` em waitlisted throws `cannotDischargeWaitlisted` |
| `testReadmitWaitlistedThrows` | `readmit()` em waitlisted throws `cannotReadmitWaitlisted` |
| `testNewPatientStartsAsWaitlisted` | `Patient.init(...)` cria com status `.waitlisted` |
| `testWithdrawReasonValues` | Todos os raw values do enum `WithdrawReason` |

### Application

| Teste | Verifica |
|-------|----------|
| `testAdmitPatient_success` | Handler admite paciente waitlisted, persiste, publica evento |
| `testAdmitPatient_notFound` | Retorna `ADM-001` |
| `testAdmitPatient_alreadyActive` | Retorna `ADM-002` |
| `testAdmitPatient_discharged` | Retorna `ADM-003` |
| `testWithdraw_success` | Handler remove da fila, persiste, publica evento |
| `testWithdraw_notFound` | Retorna `WDR-001` |
| `testWithdraw_alreadyDischarged` | Retorna `WDR-002` |
| `testWithdraw_activePatient` | Retorna `WDR-003` |
| `testWithdraw_invalidReason` | Retorna `WDR-004` |

### Testes Existentes a Ajustar

| Teste | Mudança |
|-------|---------|
| Todos os testes de `RegisterPatient` | Assertar `status == .waitlisted` ao invés de `.active` |
| `PatientFixture` | Se o fixture cria pacientes para testes de discharge/readmit, garantir que o paciente é criado como `.waitlisted` e depois `.admit()` antes de testar discharge |

---

## 12. Ordem de Implementação (Pipeline)

```
1. domain-modeler
   ├── PatientStatus.swift (add .waitlisted)
   ├── WithdrawReason.swift (novo)
   ├── WithdrawInfo.swift (novo)
   ├── PatientErrors.swift (4 novos cases)
   ├── PatientEvents.swift (2 novos events)
   ├── Patient.swift (withdrawInfo field, default .waitlisted)
   └── PatientLifecycle.swift (admit, withdraw, proteger discharge/readmit)

2. test-writer
   └── Testes de domain (12 testes)

3. application-orchestrator
   ├── AdmitPatient/ (command, usecase, handler, error)
   └── WithdrawFromWaitlist/ (command, usecase, handler, error)

4. test-writer
   └── Testes de application (9 testes)

5. infra-implementer
   ├── Migration (2026_04_12_AddWaitlistSupport.swift)
   ├── PatientDatabaseModels.swift (4 colunas)
   ├── PatientDatabaseMapper.swift (withdrawInfo mapping)
   ├── PatientController.swift (2 endpoints)
   ├── RequestDTOs.swift (WithdrawPatientRequest)
   ├── ServiceContainer.swift (2 handlers)
   └── configure.swift (registrar migration)

6. code-reviewer
   └── Review completo

7. ts-quality-checker (se aplicável ao Swift)
   └── Strict concurrency, Sendable compliance

8. integration-validator
   └── Build + testes + cobertura
```

---

## 13. Commit Convention

```
feat(registry/waitlist): add waitlist lifecycle to Patient aggregate

- PatientStatus gains .waitlisted case (new patients start here)
- New VOs: WithdrawReason, WithdrawInfo
- New domain methods: Patient.admit(), Patient.withdraw()
- discharge() and readmit() protected against waitlisted state
- New events: PatientAdmittedEvent, PatientWithdrawnFromWaitlistEvent
- New use cases: AdmitPatient (ADM-xxx), WithdrawFromWaitlist (WDR-xxx)
- New endpoints: POST /patients/:id/admit, POST /patients/:id/withdraw
- Migration: DEFAULT status changed to 'waitlisted', withdraw columns added
- Existing patients remain 'active' (no data migration)
- 4 new PatientError cases (PAT-014 to PAT-017)

Pipeline: [domain-modeler, test-writer, application-orchestrator, infra-implementer, code-reviewer]
```
