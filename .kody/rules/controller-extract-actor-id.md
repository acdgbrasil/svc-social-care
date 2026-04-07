---
title: "Controller mutations must extract actorId from authenticated user"
scope: "file"
path: ["Sources/social-care-s/IO/HTTP/Controllers/**/*.swift"]
severity_min: "critical"
languages: ["swift"]
buckets: ["security"]
enabled: true
---

## Instructions

Every controller handler that performs a mutation (POST, PUT, PATCH, DELETE) must extract the actor identity via `req.extractActorId()` and pass it into the command.

This method:
1. Calls `req.requireAuthenticatedUser()` to ensure the request is authenticated
2. Returns `user.userId` from the JWT-validated `AuthenticatedUser`
3. The actorId is then injected into the command for audit trail

Flag:
- Mutation handlers that don't call `req.extractActorId()` or `req.requireAuthenticatedUser()`
- Mutation handlers that hardcode or fabricate an actor identity
- GET handlers are exempt (read-only operations)

## Examples

### Bad example
```swift
@Sendable
private func register(req: Request) async throws -> Response {
    let body = try req.content.decode(RegisterPatientRequest.self)
    // Missing actorId extraction — no audit trail
    let id = try await req.services.registerPatient.handle(
        body.toCommand(actorId: "unknown")
    )
    return try await StandardResponse(data: IdResponse(id: id))
        .encodeResponse(status: .created, for: req)
}
```

### Good example
```swift
@Sendable
private func register(req: Request) async throws -> Response {
    let actorId = try req.extractActorId()
    let body = try req.content.decode(RegisterPatientRequest.self)
    let id = try await req.services.registerPatient.handle(
        body.toCommand(actorId: actorId)
    )
    return try await StandardResponse(data: IdResponse(id: id))
        .encodeResponse(status: .created, for: req)
}
```
