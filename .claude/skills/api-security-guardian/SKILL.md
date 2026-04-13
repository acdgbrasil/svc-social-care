---
name: api-security-guardian
description: >
  API Security expert for Swift/Vapor REST APIs. Covers input validation, rate limiting,
  CORS, security headers, error handling, and abuse protection.
  Use when auditing or hardening API endpoints.
user_invocable: true
---

# API Security Guardian — Vapor 4

## Security Dimensions

### 1. Transport Security
- All connections (DB, NATS, external APIs) use TLS
- HSTS header present (`Strict-Transport-Security: max-age=31536000; includeSubDomains`)

### 2. Input Validation
- All DTOs conform to `Validatable` with field constraints
- Path parameters validated as UUID before use
- Query parameters typed and bounded
- Request body size limited (`app.routes.defaultMaxBodySize = "256kb"`)
- String fields have max length, array fields have max count

### 3. Authentication
- JWT middleware on ALL protected routes
- Claims verified: `exp`, `iss`, `aud`
- Empty bearer token rejected early
- Service account allowlist for introspection

### 4. Rate Limiting
- Per-IP rate limit on all endpoints
- Per-user rate limit on mutation endpoints
- Stricter limits on search/enumeration endpoints

### 5. CORS
- Explicit restrictive config (or `.none` for API-only service)
- No wildcard `*` with credentials

### 6. Security Headers
```swift
struct SecurityHeadersMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.replaceOrAdd(name: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains")
        response.headers.replaceOrAdd(name: "X-Content-Type-Options", value: "nosniff")
        response.headers.replaceOrAdd(name: "X-Frame-Options", value: "DENY")
        response.headers.replaceOrAdd(name: "Cache-Control", value: "no-store")
        response.headers.replaceOrAdd(name: "Referrer-Policy", value: "strict-origin-when-cross-origin")
        return response
    }
}
```

### 7. Error Handling
- `safeContext` to client, full `context` to logs only
- No stack traces in production
- `VERBOSE_ERRORS` blocked in production
- No build version or internal IDs in response headers

### 8. Response Safety
- No PII over-fetching (prefer sub-resource endpoints)
- `Content-Type: application/json` explicit
- `Cache-Control: no-store` on PII responses
- Pagination on all list endpoints (limit + offset, max 100)

## Middleware Stack Order
```
SecurityHeadersMiddleware  -> Security headers on all responses
RateLimitMiddleware        -> Throttle abusive clients
ContentTypeMiddleware      -> Enforce application/json on mutations
CORSMiddleware             -> Restrictive CORS policy
AppErrorMiddleware         -> Translate errors to safe HTTP responses
JWTAuthMiddleware          -> Verify JWT and extract roles
// RoleGuardMiddleware is per-route group, not global
```
