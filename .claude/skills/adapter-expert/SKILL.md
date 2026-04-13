---
name: adapter-expert
description: >
  Expert skill for implementing the IO/Adapter layer: Vapor controllers, DTOs,
  SQLKit repositories, middleware (JWT, RBAC, errors), event bus (Outbox, NATS),
  database migrations, and external API clients.
  Use when the user mentions: controller, route, middleware, repository, migration,
  SQLKit, Vapor, DTO, event bus, outbox, NATS.
user_invocable: true
---

# Adapter Expert — Swift 6.2 / Vapor 4 / SQLKit

You are the IO layer specialist. This layer connects domain and application to the real world.

## Architecture

```
IO/
  HTTP/
    Bootstrap/     — configure.swift, ServiceContainer
    Controllers/   — Route handlers (6 controllers)
    DTOs/          — RequestDTOs, ResponseDTOs
    Middleware/     — AppError, JWTAuth, RoleGuard
    Auth/          — ZitadelJWTPayload, AuthenticatedUser, TokenIntrospector
    Validation/    — CrossValidator, MetadataValidator
    Extensions/    — Request+ActorId
  Persistence/
    SQLKit/        — Repositories, Mappers, Migrations, Outbox
  EventBus/        — OutboxEventBus, NATSPublisher, NATSSubscriber
  PeopleContext/   — PeopleContextPersonValidator
```

## Controller Pattern
```swift
struct PatientController: RouteCollection {
    let container: ServiceContainer

    func boot(routes: RoutesBuilder) throws {
        let patients = routes.grouped("api", "v1", "patients")

        // Read routes (social_worker, owner, admin)
        let read = patients.grouped(RoleGuardMiddleware("social_worker", "owner", "admin"))
        read.get(use: list)
        read.get(":patientId", use: getById)

        // Write routes (social_worker only)
        let write = patients.grouped(RoleGuardMiddleware("social_worker"))
        write.post(use: register)
        write.post(":patientId", "family-members", use: addFamilyMember)
    }

    func register(req: Request) async throws -> Response {
        let dto = try req.content.decode(RegisterPatientRequest.self)
        let actorId = try req.actorId()
        let command = dto.toCommand(actorId: actorId)

        let result = try await container.registerPatientHandler.handle(command)

        switch result {
        case .success(let patient):
            let response = PatientResponse(from: patient)
            return try await StandardResponse.created(response).encodeResponse(for: req)
        case .failure(let error):
            throw error.toAppError()
        }
    }
}
```

## DTO Pattern
```swift
// Request DTO
struct RegisterPatientRequest: Content {
    let personId: String
    let fullName: String
    let cpf: String
    let birthDate: Date
    let initialDiagnoses: [DiagnosisDraftDTO]

    func toCommand(actorId: UUID) -> RegisterPatientCommand {
        RegisterPatientCommand(
            personalData: self,
            actorId: actorId
        )
    }
}

// Response DTO
struct StandardResponse<T: Content>: Content {
    let data: T
    let meta: ResponseMeta

    static func ok(_ data: T) -> StandardResponse {
        StandardResponse(data: data, meta: ResponseMeta(timestamp: Date()))
    }
}
```

## Repository Pattern (SQLKit)
```swift
struct SQLKitPatientRepository: PatientRepository, Sendable {
    let database: any SQLDatabase

    func findById(_ id: UUID) async throws -> Patient? {
        let rows = try await database.select()
            .columns("*")
            .from("patients")
            .where("id", .equal, id)
            .all()
        guard let row = rows.first else { return nil }
        return try PatientDatabaseMapper.toDomain(row)
    }

    func save(_ patient: Patient) async throws {
        try await database.transaction { tx in
            // 1. Upsert patient
            // 2. Save child entities
            // 3. Write events to outbox
            // 4. Write audit trail
        }
    }
}
```

## Middleware Chain (order matters)
```swift
// In configure.swift
app.middleware = .init()
app.middleware.use(SecurityHeadersMiddleware())  // HSTS, nosniff, DENY
app.middleware.use(AppErrorMiddleware())          // Error translation
app.middleware.use(JWTAuthMiddleware())           // JWT verification
// RoleGuardMiddleware is per-route, not global
```

## Security Rules
- `try/catch` ALLOWED here — but MUST translate to `AppError` at boundary
- SQL uses parameterized queries — NEVER `unsafeRaw` with user input
- Use `\(ident: tableName)` for dynamic identifiers, `\(bind: value)` for values
- ActorId from JWT `sub` claim (Request+ActorId), never from request header
- Responses via `StandardResponse<T>` with `meta.timestamp`
- Error responses use `safeContext` only — `context` goes to logs
- JWT must verify `exp`, `iss`, `aud`
- `RoleGuardMiddleware` on every protected route
