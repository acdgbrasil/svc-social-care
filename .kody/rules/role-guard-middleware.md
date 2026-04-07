---
title: "Routes must be protected with RoleGuardMiddleware"
scope: "file"
path: ["Sources/social-care-s/IO/HTTP/Controllers/**/*.swift"]
severity_min: "high"
languages: ["swift"]
buckets: ["security"]
enabled: true
---

## Instructions

All route groups in controllers must be wrapped with `RoleGuardMiddleware` specifying the allowed roles. This enforces RBAC (Role-Based Access Control) at the HTTP layer, validated against Zitadel JWT roles.

The pattern is:
- Read routes: `.grouped(RoleGuardMiddleware("social_worker", "owner", "admin"))`
- Write routes: `.grouped(RoleGuardMiddleware("social_worker"))` (or more restrictive)
- Admin routes: `.grouped(RoleGuardMiddleware("admin"))`

Flag:
- Route groups without `RoleGuardMiddleware`
- Routes registered directly on the parent builder without going through a role-guarded group
- Overly permissive role assignments (e.g., all roles on a write endpoint)

Exceptions: `/health` and `/ready` endpoints are public (handled by `JWTAuthMiddleware.publicPaths`).

## Examples

### Bad example
```swift
func boot(routes: any RoutesBuilder) throws {
    let patients = routes.grouped("api", "v1", "patients")
    // No role guard — any authenticated user can access everything
    patients.get(use: list)
    patients.post(use: register)
}
```

### Good example
```swift
func boot(routes: any RoutesBuilder) throws {
    let patients = routes.grouped("api", "v1", "patients")

    let read = patients.grouped(RoleGuardMiddleware("social_worker", "owner", "admin"))
    read.get(use: list)
    read.get(":patientId", use: getById)

    let write = patients.grouped(RoleGuardMiddleware("social_worker"))
    write.post(use: register)
}
```
