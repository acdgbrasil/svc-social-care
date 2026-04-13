---
name: red-team-scanner
description: >
  Offensive security pentester for Swift/Vapor vulnerability detection.
  Hunts exploitable vulnerabilities with PoCs and CVSS scoring.
  Use when performing penetration testing or vulnerability assessment.
user_invocable: true
---

# Red Team Scanner — Swift/Vapor SAST

## Attack Vectors (Swift/Vapor specific)

### 1. SQL Injection
- Search for `unsafeRaw` in SQLKit queries
- Check if user input flows to `.from()`, `.where()` without parameterization
- Verify `\(bind:)` used for values, `\(ident:)` for identifiers

### 2. Broken Authentication
- JWT claim verification (iss, aud, exp, nbf)
- Algorithm restriction (reject `none`)
- Token introspection security
- Empty bearer token handling

### 3. Broken Access Control (IDOR)
- Role checks present but ownership missing
- Patient ID in URL accessible by any authenticated user
- Enumeration via sequential/predictable IDs

### 4. Security Misconfiguration
- PostgreSQL TLS disabled
- NATS without auth/TLS
- Container running as root
- Default/fallback credentials in code
- VERBOSE_ERRORS in production

### 5. Sensitive Data Exposure
- PII in logs (CPF, names, addresses)
- PII in error responses (context vs safeContext)
- Build version in response headers
- Audit trail exposing full event payloads

### 6. SSRF
- External API calls with user-controlled input (PeopleContext validator)
- URL construction from user parameters

### 7. Business Logic Flaws
- Missing optimistic concurrency (version check on save)
- Fail-open validation (people-context unreachable = allow)
- State machine bypass in domain aggregates

### 8. Concurrency Vulnerabilities
- Data races in `@unchecked Sendable` types
- `nonisolated(unsafe)` suppressing compiler safety
- TOCTOU in check-then-act patterns without transactions

### 9. Dependency Vulnerabilities
- SwiftPM packages with known CVEs
- Outdated dependencies

### 10. Event Injection
- NATS messages without authentication
- No schema validation on inbound events
- No HMAC signature verification

## PoC Requirements
Every finding MUST include:
- Exact file and line number
- Description of the vulnerability
- Proof of Concept (curl command, code snippet, or attack scenario)
- CVSS score
- Remediation with Swift code

## Scoring: Security Score XX/100
