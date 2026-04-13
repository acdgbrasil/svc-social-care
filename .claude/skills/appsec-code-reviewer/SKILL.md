---
name: appsec-code-reviewer
description: >
  Defensive secure code review for Swift/Vapor. 10-point security checklist
  adapted for Swift concurrency, SQLKit, Vapor middleware, and LGPD compliance.
  Use when performing security-focused code reviews.
user_invocable: true
---

# AppSec Code Reviewer — Swift/Vapor

## 10-Point Security Checklist

### 1. Input Validation
- [ ] All DTOs validated (Vapor `Validatable` or domain smart constructors)
- [ ] Path params validated as UUID
- [ ] Query params typed and bounded
- [ ] Body size limited
- [ ] String/array length validated

### 2. Output Safety
- [ ] `safeContext` in error responses (not `context`)
- [ ] No stack traces in production
- [ ] No internal identifiers in headers
- [ ] `Cache-Control: no-store` on PII

### 3. Authentication & Authorization
- [ ] JWT verifies `exp`, `iss`, `aud`
- [ ] `RoleGuardMiddleware` on all protected routes
- [ ] Ownership checks (IDOR prevention)
- [ ] ActorId from JWT `sub`

### 4. Data Protection (LGPD)
- [ ] No PII in logs
- [ ] DB connection uses TLS
- [ ] NATS authenticated + encrypted
- [ ] Audit trail tamper-resistant

### 5. SQL Safety
- [ ] Parameterized queries via SQLKit builder
- [ ] No `unsafeRaw` with user input
- [ ] `\(ident:)` for identifiers, `\(bind:)` for values

### 6. Dependency Health
- [ ] `Package.resolved` committed
- [ ] Dependencies from trusted publishers
- [ ] No known CVEs

### 7. Security Headers
- [ ] HSTS, X-Content-Type-Options, X-Frame-Options
- [ ] Cache-Control: no-store
- [ ] No X-Build-Version in production

### 8. Error Handling
- [ ] No empty catch blocks
- [ ] No `try!` in production
- [ ] Global error middleware catches all
- [ ] Errors mapped to HTTP status codes

### 9. Concurrency Safety
- [ ] No `@unchecked Sendable` without justification
- [ ] No `nonisolated(unsafe)` without justification
- [ ] No data races in NIO callbacks
- [ ] Optimistic concurrency on aggregate save

### 10. Infrastructure
- [ ] No hardcoded credentials
- [ ] Fail-fast on missing env vars
- [ ] Container runs as non-root
- [ ] Health endpoints don't leak state

## Issue Format
```markdown
### [SEVERITY] Short description
**File**: `path/to/file.swift:42`
**Category**: SQL Safety

**Before** (insecure):
(code)

**After** (secure):
(code)

**Why it matters**: ...
```

## Verdict: APPROVED or NEEDS FIXES
