---
name: auth-session-security
description: >
  Identity & Access Management expert for Swift/Vapor with Zitadel OIDC.
  Covers JWT verification, RBAC, token introspection, service accounts, audit trail.
  Use when auditing or implementing authentication/authorization.
user_invocable: true
---

# Auth & Session Security — Vapor 4 + Zitadel OIDC

## JWT Verification (ZitadelJWTPayload)

### Required Claims
```swift
struct ZitadelJWTPayload: JWTPayload, Sendable {
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var iss: IssuerClaim
    var aud: AudienceClaim
    var projectRoles: [String: [String: String]]?

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
        try iss.verifyIntendedRecipient(is: expectedIssuer)
        try aud.verifyIntendedAudience(includes: expectedAudience)
    }
}
```

### Zitadel Configuration
- **Issuer**: `https://auth.acdgbrasil.com.br`
- **JWKS**: `https://auth.acdgbrasil.com.br/oauth/v2/keys`
- **Roles claim path**: `urn:zitadel:iam:org:project:roles`
- **Client ID (Native)**: `363110312318140539`

## RBAC (RoleGuardMiddleware)
- Roles extracted from JWT `projectRoles` claim
- Guard applied per-route group (not global)
- Roles: `social_worker` (read+write), `owner` (read), `admin` (all)
- No role escalation via parameter manipulation

## Token Introspection (Service Accounts)
- Fallback for JWTs without roles (service accounts)
- Gated by explicit `ALLOWED_SERVICE_ACCOUNTS` allowlist
- Uses Basic auth to Zitadel introspection endpoint
- URL must be validated as HTTPS before use
- Bearer token must not be empty

## Actor ID (Audit Trail)
- Extracted from JWT `sub` claim (NOT from request header)
- `Request+ActorId` extension wraps this safely
- All mutation commands carry `actorId`
- Stored in audit trail with every domain event

## IDOR Prevention
- RBAC checks role, not resource ownership
- Need: patient assignment model (professional -> patient)
- Validate ownership before allowing access
- `owner` role should be scoped to self-patient only

## Infrastructure Auth
- PostgreSQL: TLS required (`.require` or `.prefer`)
- NATS: authentication (nkey/token) + TLS
- No fallback credentials in code — fail-fast if env vars missing
