# Security Code Review -- social-care (Final Defensive Pass)
**Date**: 2026-04-11
**Reviewer**: secure-code-reviewer agent (Claude Opus 4.6)
**Scope**: Sources/social-care-s/ (Swift 6.2 / Vapor 4 REST API)

## Summary
- Issues found: 13 (Critical: 2 | High: 4 | Medium: 5 | Low: 2 | Info: 0)
- Top 3 priorities:
  1. CRITICAL -- CPF logged in plaintext across multiple call sites (PII leakage in production logs)
  2. CRITICAL -- TOCTOU race condition on Patient aggregate save (no optimistic concurrency check)
  3. HIGH -- NATSMessageHandler has unsynchronised mutable state (`@unchecked Sendable` with `var buffer`)

## Positive Findings
1. **Solid domain modeling** -- Branded types (CPF, NIS, PatientId, PersonId) with validating constructors prevent primitive obsession and catch invalid data at the domain boundary.
2. **AllowedLookupTables whitelist** -- Lookup table names are validated against a static `Set<String>` before being used in SQL, which effectively prevents table-name injection for the controlled paths.
3. **Actor-based command handlers** -- All write use cases are implemented as Swift actors, providing serial execution per handler and preventing concurrent mutation of shared state within each handler.
4. **Transactional Outbox pattern** -- Events are persisted in the same DB transaction as the aggregate, ensuring at-least-once delivery semantics.
5. **Structured error contract** -- AppError with `safeContext` vs `context` separation shows awareness of information leakage. VERBOSE_ERRORS is behind an env flag.
6. **Pagination with cursor** -- ListPatients uses cursor-based pagination with a validated limit (1-100), preventing unbounded result sets.
7. **JWT verification with JWKS** -- Tokens are verified using remotely-fetched JWKS keys, not a static secret, which allows key rotation.

## Issues

### [CRITICAL] PII (CPF) logged in plaintext -- MUST_FIX
**File**: `Sources/social-care-s/Application/Registry/LinkPersonId/Services/LinkPersonIdCommandHandler.swift:26,40`
**Category**: Data Protection / Logging

**Problem**: The CPF (Brazilian national ID, classified as PII under LGPD) is written to logs in plaintext in multiple locations. The `LinkPersonIdCommandHandler` logs the raw CPF value on both validation failure and lookup miss. In a production environment with centralized logging (ELK, CloudWatch, etc.), this creates a persistent store of PII that violates data minimization principles and LGPD compliance requirements.

**Before** (insecure):
```swift
// LinkPersonIdCommandHandler.swift:26
logger.warning("Invalid CPF in event: \(command.cpf)")

// LinkPersonIdCommandHandler.swift:40
logger.info("No patient found for CPF \(command.cpf) -- skipping link")
```

**After** (secure):
```swift
// Mask CPF: show only last 4 digits
private func maskedCpf(_ cpf: String) -> String {
    let clean = cpf.filter(\.isNumber)
    guard clean.count >= 4 else { return "***" }
    return "***.\(clean.suffix(4))"
}

logger.warning("Invalid CPF in event: \(maskedCpf(command.cpf))")
logger.info("No patient found for CPF \(maskedCpf(command.cpf)) -- skipping link")
```

**Why it matters**: Centralised log stores become a breach target. Leaking CPFs in logs means a log exfiltration also becomes a PII breach under LGPD, with notification obligations and potential fines.

---

### [CRITICAL] TOCTOU race condition on Patient aggregate -- no optimistic concurrency control -- MUST_FIX
**File**: `Sources/social-care-s/IO/Persistence/SQLKit/SQLKitPatientRepository.swift:19-21`
**Category**: Concurrency Safety / Business Logic

**Problem**: The Patient aggregate has a `version` field, but `save()` performs an upsert with `onConflict(with: "id") { set(excludedContentOf:) }` that unconditionally overwrites the existing row. There is no `WHERE version = expectedVersion` check. Two concurrent requests updating the same patient will silently last-write-wins, losing the first writer's changes. This is especially dangerous for the delete-and-insert pattern on child tables -- a concurrent write can delete the other writer's family members, diagnoses, or assessments.

**Before** (insecure):
```swift
// SQLKitPatientRepository.swift:19-21
try await tx.insert(into: "patients")
    .model(data.patient)
    .onConflict(with: "id") { try $0.set(excludedContentOf: data.patient) }
    .run()
```

**After** (secure):
```swift
// 1. First try to UPDATE with version check
let updateCount = try await tx.update("patients")
    .set(model: data.patient)
    .where("id", .equal, data.patient.id)
    .where("version", .equal, data.patient.version - 1) // expect previous version
    .run()
// Note: SQLKit update doesn't return row count directly.
// Alternative: use raw SQL with RETURNING or check via SELECT after.

// Preferred approach: raw SQL with version guard
let rows = try await tx.raw("""
    UPDATE patients SET
        person_id = \(bind: data.patient.person_id),
        version = \(bind: data.patient.version),
        -- ... all columns ...
    WHERE id = \(bind: data.patient.id)
      AND version = \(bind: data.patient.version - 1)
    RETURNING id
    """).all()

guard !rows.isEmpty else {
    throw PersistenceConflictError.optimisticLockFailure(
        aggregateId: data.patient.id.uuidString,
        expectedVersion: data.patient.version - 1
    )
}

// Then proceed with child table delete-and-insert
```

**Why it matters**: In a multi-user social care application, two social workers editing the same patient record simultaneously will silently overwrite each other's changes. This can lead to data loss on family members, diagnoses, or protection records -- all of which have legal significance.

---

### [HIGH] NATSMessageHandler has data race on mutable `buffer` -- MUST_FIX
**File**: `Sources/social-care-s/IO/EventBus/NATSEventSubscriber.swift:94-99`
**Category**: Concurrency Safety

**Problem**: `NATSMessageHandler` is marked `@unchecked Sendable` but contains a mutable `var buffer: String` that is mutated in `channelRead` (called on NIO event loop) and read/written in `processBuffer`. While NIO typically calls handlers on a single event loop, the `@unchecked Sendable` annotation suppresses compiler warnings and the class is shared via the actor's `connectAndListen` method. If the channel pipeline is reconfigured or if SwiftNIO schedules callbacks on different threads (which is possible during reconnection), this is a data race.

**Before** (insecure):
```swift
private final class NATSMessageHandler: ChannelInboundHandler, @unchecked Sendable {
    // ...
    private var buffer: String = ""
```

**After** (secure):
```swift
// Option A: Use NIOLockedValueBox for thread-safe access
private final class NATSMessageHandler: ChannelInboundHandler, @unchecked Sendable {
    private let _buffer = NIOLockedValueBox<String>("")

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        guard let str = buf.readString(length: buf.readableBytes) else { return }
        _buffer.withLockedValue { $0.append(str) }
        processBuffer(context: context)
    }
    // ... processBuffer reads/writes via _buffer.withLockedValue { ... }
}

// Option B (simpler): Assert handler is always on the same event loop
// by adding an eventLoop assertion at the top of channelRead
```

**Why it matters**: A data race on the message buffer can cause corrupted NATS protocol parsing, leading to dropped events, partial message processing, or crashes in production.

---

### [HIGH] `nonisolated(unsafe) var channel` in NATSEventPublisher -- MUST_FIX
**File**: `Sources/social-care-s/IO/EventBus/NATSEventPublisher.swift:33`
**Category**: Concurrency Safety

**Problem**: The `channel` property is marked `nonisolated(unsafe)` inside an actor, which tells the compiler to skip isolation checks. This property is read in `publish()` (actor-isolated) and potentially written in `ensureConnected()` (also actor-isolated), so it appears safe *within* the actor. However, `nonisolated(unsafe)` is a code smell that can mask future bugs if the property is ever accessed from a non-isolated context (e.g., `disconnect()` is `public` and could be called from any context). The `readInbound()` extension on `Channel` is also a no-op that returns an empty buffer, meaning the NATS handshake never actually reads the server's INFO frame.

**Before**:
```swift
private nonisolated(unsafe) var channel: Channel?
```

**After**:
```swift
// Remove nonisolated(unsafe) -- let the actor isolation enforce safety
private var channel: Channel?
```

**Why it matters**: `nonisolated(unsafe)` is an escape hatch that disables the very concurrency safety guarantees Swift 6.2 provides. Removing it lets the compiler enforce correct access patterns.

---

### [HIGH] Unvalidated `limit` query parameter enables resource exhaustion -- MUST_FIX
**File**: `Sources/social-care-s/IO/HTTP/Controllers/PatientController.swift:29`
**Category**: Input Validation

**Problem**: The `list` endpoint reads a `limit` query parameter with a default of 20 but does NOT validate its upper bound at the controller level. While the `ListPatientsQueryHandler` validates `1..100`, the controller passes the raw integer to the query handler. However, the `fetchLimit = limit + 1` in the repository means a `limit=100` results in fetching 101 rows. More critically, a malicious client can send `limit=0` or `limit=-1` which passes the controller but should be rejected. The query handler does validate, but the error path returns a 500-class error rather than a clean 400 because the handler throws `ListPatientsError.invalidLimit` which gets caught by `AppErrorMiddleware` -- this is actually correct BUT the controller does `let limit = req.query[Int.self, at: "limit"] ?? 20` which silently defaults non-integer values, and a limit of e.g. `99999` would be rejected by the handler but only AFTER initiating the query construction.

More importantly: the **audit trail endpoint** (`getAuditTrail`) has **NO pagination at all** -- it returns all matching rows, enabling a denial-of-service attack by requesting the full audit trail of a heavily-used patient.

**Before**:
```swift
// PatientController.swift:147-161 -- audit trail has no limit
let rows = try await query
    .orderBy("occurred_at", .descending)
    .all(decoding: AuditTrailModel.self)
```

**After**:
```swift
// Add pagination to audit trail
let limit = min(req.query[Int.self, at: "limit"] ?? 50, 200)
let offset = req.query[Int.self, at: "offset"] ?? 0

let rows = try await query
    .orderBy("occurred_at", .descending)
    .limit(limit)
    .offset(offset)
    .all(decoding: AuditTrailModel.self)
```

**Why it matters**: An attacker with valid credentials can exhaust server memory by requesting unbounded audit trails for patients with many events, causing OOM kills in the container.

---

### [HIGH] AppErrorMiddleware logs full `context` dict which may contain PII -- MUST_FIX
**File**: `Sources/social-care-s/IO/HTTP/Middleware/AppErrorMiddleware.swift:52-53`
**Category**: Data Protection / Logging

**Problem**: The `logAppError` function logs the full `context` dictionary, which may include PII like patient names, CPFs, or other sensitive data. The AppError model distinguishes between `context` (raw, for debugging) and `safeContext` (sanitised, for external use), but the logging function uses `context`, not `safeContext`.

**Before** (insecure):
```swift
private func logAppError(_ appError: AppError, request: Request) {
    let contextDescription = appError.context.map { "\($0.key): \($0.value.value)" }.joined(separator: ", ")
    request.logger.error("\(appError.code) [\(appError.kind)] \(appError.message) context: {\(contextDescription)}")
}
```

**After** (secure):
```swift
private func logAppError(_ appError: AppError, request: Request) {
    let safeDescription = appError.safeContext.map { "\($0.key): \($0.value.value)" }.joined(separator: ", ")
    request.logger.error("\(appError.code) [\(appError.kind)] \(appError.message) safeContext: {\(safeDescription)}")
}
```

**Why it matters**: The entire point of having a `safeContext` field is to prevent PII from leaking into logs. Using `context` instead defeats this design and creates LGPD exposure.

---

### [MEDIUM] NATS subject injection via unvalidated `typeName` -- SHOULD_FIX
**File**: `Sources/social-care-s/IO/EventBus/NATSEventPublisher.swift:82-83`
**Category**: Input Validation

**Problem**: The NATS subject is constructed by string interpolation: `"social-care.events.\(typeName)"`. The `typeName` comes from `String(describing: eventType)` in `DomainEventRegistry`, which is controlled code. However, the NATS protocol uses spaces and `\r\n` as delimiters. If a `typeName` ever contained a space or newline (e.g., through a compromised event registration or future refactor), it would inject arbitrary NATS protocol commands via the raw TCP connection.

**Before**:
```swift
let subject = "social-care.events.\(typeName)"
let pubLine = "PUB \(subject) \(payload.count)\r\n"
```

**After**:
```swift
let sanitizedName = typeName.filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "_" }
let subject = "social-care.events.\(sanitizedName)"
guard subject.count < 256 else { throw NATSError.invalidSubject(typeName) }
let pubLine = "PUB \(subject) \(payload.count)\r\n"
```

**Why it matters**: A NATS protocol injection could publish messages to arbitrary subjects or execute NATS commands (SUB, UNSUB, etc.) on the shared connection, potentially exfiltrating data or disrupting event routing.

---

### [MEDIUM] `readInbound()` is a no-op -- NATS handshake is incomplete -- SHOULD_FIX
**File**: `Sources/social-care-s/IO/EventBus/NATSEventPublisher.swift:136-143`
**Category**: Error Handling / Cryptographic Usage

**Problem**: The `readInbound()` extension method on `Channel` sleeps for 100ms and then returns an empty buffer -- it never actually reads the server's INFO frame. This means: (1) the publisher never validates the server identity, (2) if the server requires authentication the CONNECT will fail silently, and (3) there is no verification that the connection is to a legitimate NATS server (no TLS, no auth token in CONNECT).

**Before**:
```swift
private extension Channel {
    func readInbound() async throws -> ByteBuffer? {
        var buffer = allocator.buffer(capacity: 1024)
        try? await Task.sleep(for: .milliseconds(100))
        return buffer  // Always returns empty buffer!
    }
}
```

**After**:
```swift
// Use a proper NIO ChannelHandler to read the INFO frame,
// or use a real NATS client library (e.g., nats.swift)
// instead of raw TCP protocol implementation.
```

**Why it matters**: The handshake is cosmetic -- the publisher sends CONNECT without confirming the server accepted it. Protocol errors or auth failures go undetected, and messages may be silently dropped.

---

### [MEDIUM] Lookup `from(tableName)` in SQLKitLookupRepository passes table name from application layer -- SHOULD_FIX
**File**: `Sources/social-care-s/IO/Persistence/SQLKit/SQLKitLookupRepository.swift:20`
**Category**: SQL Safety

**Problem**: While `LookupController.list()` validates against `AllowedLookupTables`, the `SQLKitLookupRepository.exists(id:in:)` method receives a `table` string parameter that is used directly in `.from(table)`. The validation happens at the *application* layer (`CreateLookupItemCommandHandler` checks `AllowedLookupTables`), but the *repository* layer trusts this input. If a new code path ever calls `exists(id:in:)` without going through the command handler validation, it would be vulnerable. Defense-in-depth requires the repository to also validate.

**Before**:
```swift
func exists(id: LookupId, in table: String) async throws -> Bool {
    // table used directly in .from(table)
    let count = try await db.select()
        .from(table)
        // ...
```

**After**:
```swift
func exists(id: LookupId, in table: String) async throws -> Bool {
    guard AllowedLookupTables.all.contains(table) else {
        throw LookupAdminError.tableNotAllowed(table)
    }
    let count = try await db.select()
        .from(table)
        // ...
```

**Why it matters**: Defense-in-depth. The repository is a security boundary -- it should not trust that callers have validated inputs, as code evolves and new callers may be added.

---

### [MEDIUM] Approve lookup request does not validate `tableName` against AllowedLookupTables -- SHOULD_FIX
**File**: `Sources/social-care-s/Application/Configuration/LookupRequest/Services/ApproveLookupRequestCommandHandler.swift:26-34`
**Category**: Input Validation / Business Logic

**Problem**: When a lookup request is approved, the handler reads `request.tableName` from the database (previously validated on creation) and calls `lookupRepository.createItem(in: request.tableName, ...)`. However, between creation and approval, the `AllowedLookupTables` set could have changed (e.g., a table was removed from the whitelist). The approve handler should re-validate that the table is still allowed before creating the item.

**Before**:
```swift
// No tableName validation on approval
try await lookupRepository.createItem(
    in: request.tableName,
    id: UUID(),
    codigo: request.codigo,
    descricao: request.descricao,
    metadata: nil
)
```

**After**:
```swift
guard AllowedLookupTables.all.contains(request.tableName) else {
    throw LookupRequestError.invalidTableName(request.tableName)
}

try await lookupRepository.createItem(
    in: request.tableName,
    id: UUID(),
    codigo: request.codigo,
    descricao: request.descricao,
    metadata: nil
)
```

**Why it matters**: If the whitelist evolves (tables removed), previously-created pending requests could be used to write to now-disallowed tables.

---

### [MEDIUM] `LookupController.list` reflects `tableName` in error message -- SHOULD_FIX
**File**: `Sources/social-care-s/IO/HTTP/Controllers/LookupController.swift:41`
**Category**: Output Encoding / Error Handling

**Problem**: When a lookup table name is not in the allowed set, the error message reflects the user-supplied `tableName` back in the response: `"Dominio '\(tableName)' not found."`. While this is not XSS (JSON response), it is a minor information disclosure and violates the principle of not reflecting user input in error messages. An attacker could use this to probe for valid table names by observing different error messages.

**Before**:
```swift
throw Abort(.notFound, reason: "Dominio '\(tableName)' not found.")
```

**After**:
```swift
throw Abort(.notFound, reason: "Requested domain table not found.")
```

**Why it matters**: Error messages should not reflect user input. While low-severity, it contributes to information gathering during reconnaissance.

---

### [LOW] `print()` statements used for error logging in production code -- SHOULD_FIX
**File**: `Sources/social-care-s/IO/Persistence/SQLKit/Outbox/SQLKitOutboxRelay.swift:62,79,138`
**Category**: Error Handling / Logging

**Problem**: The outbox relay uses `print()` for error logging instead of a structured logger. `print()` output goes to stdout without timestamps, log levels, or correlation IDs, making it difficult to monitor and alert on outbox processing failures in production. It also cannot be filtered or routed by log aggregation systems.

**Before**:
```swift
print("Outbox Relay Error: \(error.localizedDescription)")
print("Failed to process outbox event \(message.id): \(error)")
```

**After**:
```swift
// Inject a Logger into the actor
private let logger: Logger

// Then use structured logging
logger.error("Outbox relay poll failed", metadata: ["error": "\(error)"])
logger.warning("Failed to process outbox event", metadata: [
    "eventId": "\(message.id)",
    "eventType": .string(message.event_type),
    "error": "\(error)"
])
```

**Why it matters**: In a containerised deployment, `print()` output may not be captured by the log aggregation pipeline, causing silent failures in event processing to go undetected.

---

### [LOW] `@unchecked Sendable` on `AnySendable` wrapping `Any` -- SHOULD_FIX
**File**: `Sources/social-care-s/shared/Error/AppError.swift:125`
**Category**: Concurrency Safety

**Problem**: `AnySendable` wraps an arbitrary `Any` value and marks itself as `@unchecked Sendable`. This means any mutable reference type (class instance, NSMutableDictionary, etc.) could be wrapped and shared across concurrency domains without protection. While current usage appears to only wrap value types (String, Int, Bool, Dict), there is no compile-time guarantee, and a future caller could wrap a mutable reference type, introducing a data race.

**Before**:
```swift
public struct AnySendable: @unchecked Sendable, Codable {
    public let value: Any
    public init(_ value: Any) { self.value = value }
}
```

**After**:
```swift
// Option A: Restrict to known safe types
public enum SafeContextValue: Sendable, Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    case dict([String: SafeContextValue])
    case null
}

// Option B: Keep AnySendable but add runtime assertion in debug
public init(_ value: Any) {
    assert(value is String || value is Int || value is Bool || value is Double
           || value is [String: Any] || value is [Any],
           "AnySendable should only wrap value types")
    self.value = value
}
```

**Why it matters**: `@unchecked Sendable` is an unsafe escape hatch. As the codebase grows, the risk of accidentally wrapping a mutable reference type increases.

---

## Tooling Recommendations

1. **SwiftLint rules**: Enable `nonisolated_unsafe` and `unchecked_sendable` custom rules to flag these escape hatches for manual review.

2. **Structured logging audit**: Run `grep -rn 'print(' Sources/` and replace all `print()` calls with structured `Logger` calls. Consider a linter rule to forbid `print()` in non-test code.

3. **PII detection in logs**: Implement a custom `LogHandler` wrapper that scans log messages for CPF patterns (`\d{3}\.\d{3}\.\d{3}-\d{2}` or 11-digit sequences) and masks them automatically as a safety net.

4. **Optimistic concurrency testing**: Add integration tests that simulate concurrent writes to the same Patient aggregate and verify that the second writer receives a conflict error.

5. **NATS client library**: Replace the custom raw-TCP NATS implementation with the official `nats.swift` client library, which handles protocol parsing, TLS, authentication, and reconnection correctly.

6. **Database query audit**: Run `grep -rn 'unsafeRaw' Sources/` periodically to catch any new raw SQL interpolation. Consider a pre-commit hook.

---

## Verdict

**NEEDS FIXES**

Items to address before production deployment:

| Priority | Issue | Tag |
|----------|-------|-----|
| 1 | CPF logged in plaintext (LGPD violation) | MUST_FIX |
| 2 | No optimistic concurrency on Patient save (data loss) | MUST_FIX |
| 3 | NATSMessageHandler data race on `buffer` | MUST_FIX |
| 4 | `nonisolated(unsafe)` on NATSEventPublisher.channel | MUST_FIX |
| 5 | Unbounded audit trail query (DoS) | MUST_FIX |
| 6 | AppErrorMiddleware logs `context` instead of `safeContext` | MUST_FIX |
| 7 | NATS subject injection via typeName | SHOULD_FIX |
| 8 | NATS readInbound() no-op handshake | SHOULD_FIX |
| 9 | LookupRepository lacks defense-in-depth table validation | SHOULD_FIX |
| 10 | Approve handler skips table re-validation | SHOULD_FIX |
| 11 | User input reflected in error message | SHOULD_FIX |
| 12 | print() instead of Logger in OutboxRelay | SHOULD_FIX |
| 13 | AnySendable wraps Any without safety | SHOULD_FIX |
