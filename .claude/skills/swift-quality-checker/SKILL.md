---
name: swift-quality-checker
description: >
  Swift 6.2 code quality checker. Audits strict concurrency, Sendable compliance,
  protocol-oriented patterns, value semantics, error handling, and naming conventions.
  Use when checking Swift code quality, concurrency safety, or API design guidelines.
user_invocable: true
---

# Swift Quality Checker — Swift 6.2

## Strict Concurrency
- All types crossing isolation boundaries MUST be `Sendable`
- No `@unchecked Sendable` without documented justification
- `nonisolated(unsafe)` requires written justification
- `actor` for mutable shared state, not `class` with locks
- No data races in NIO callbacks

## Value Semantics
- Domain types are `struct`, never `class`
- Mutation via copy, not in-place reference mutation
- Collections are value-type arrays `[T]`
- No `NSObject` subclassing in domain/application

## Protocol-Oriented Programming (PoP)
- Small, focused protocols (Single Responsibility)
- Composition over inheritance
- `some Protocol` for opaque return types
- `any Protocol` for existential containers
- Protocol extensions for default behavior

## Error Handling
- Domain: errors as `Optional` or `Result`, no `throw`
- Application: `actor` use cases, errors conform to `AppErrorConvertible`
- IO: `try/catch` allowed, translated to `AppError`
- No empty catch blocks
- No `try!` or `try?` swallowing errors silently

## Naming (Swift API Design Guidelines)
- Types: UpperCamelCase
- Functions/properties: lowerCamelCase
- Boolean: read as assertions (`isEmpty`, `hasChildren`)
- Factory methods: `create(from:)`, `make(with:)`
- Protocols: -able, -ible, -ing for capabilities

## Performance
- No unnecessary `async` on synchronous operations
- No blocking calls on event loops
- Lazy initialization for expensive resources
- Capture lists on closures to prevent retain cycles

## Reference
- `handbook/tooling/swift/` — Swift documentation
- `handbook/tooling/swift/CQRS/` — CQRS patterns
