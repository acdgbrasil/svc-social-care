---
name: codebase-health
description: >
  Codebase health check comparing CLAUDE.md declarations vs actual code reality.
  Detects drift: folders that don't exist, import boundary violations, patterns
  declared but not followed, dead code, missing test coverage.
  Trigger for: "health check", "audit", "check code quality", "verify architecture".
user_invocable: true
---

# Codebase Health Check — social-care (Swift/Vapor)

## What to Check

### 1. Folder Structure Drift
Compare CLAUDE.md declared structure vs actual `Sources/social-care-s/` contents.
Flag: missing directories, unexpected files, misplaced code.

### 2. Import Boundary Violations
- Domain/ must NOT import from Application/ or IO/
- Application/ must NOT import from IO/
- IO/ can import from Domain/ and Application/
- shared/ can be imported by all

Scan: `import` statements in every .swift file.

### 3. Prohibited Patterns
- `class` in Domain/ (should be `struct`)
- `throw` in Domain/ (should return Optional/Result)
- `@unchecked Sendable` without justification comment
- `nonisolated(unsafe)` without justification comment
- `unsafeRaw` in SQL queries
- `try!` or force unwrap `!` in production code (OK in tests)
- `Any` or `AnyObject` in domain types
- `print()` instead of `Logger` in production code

### 4. Concurrency Compliance
- All `struct` types should be `Sendable`
- Use cases should be `actor`
- No mutable `var` in shared state without actor isolation

### 5. Error Handling Chain
- Domain errors: Optional or Result (no throw)
- Application errors: AppErrorConvertible
- IO errors: translated to AppError at boundary
- No empty catch blocks

### 6. Test Coverage Map
- Domain/ tests in Tests/Domain/
- Application/ tests in Tests/Application/
- IO/ tests in Tests/IO/
- Test doubles in Tests/TestDoubles/

### 7. Security Posture Quick Scan
- JWT claims verified (iss, aud, exp)
- RoleGuardMiddleware on all protected routes
- No hardcoded credentials
- SQL parameterized (no unsafeRaw with user input)
- Audit trail on mutations

## Output Format
```markdown
# Codebase Health Report
**Date**: YYYY-MM-DD
**Score**: XX/100

| Category | Status | Issues |
|----------|--------|--------|
| Structure | OK/DRIFT | ... |
| Imports | OK/VIOLATION | ... |
| Patterns | OK/VIOLATION | ... |
| Concurrency | OK/WARNING | ... |
| Errors | OK/GAP | ... |
| Tests | XX% | ... |
| Security | OK/WARNING | ... |

## Violations (by severity)
### HIGH
### MEDIUM
### LOW

## Recommendations
```
