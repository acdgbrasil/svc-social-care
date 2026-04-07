---
title: "Domain errors must conform to AppErrorConvertible"
scope: "file"
path: ["Sources/social-care-s/Domain/**/Errors/**/*.swift", "Sources/social-care-s/Application/**/Error/**/*.swift"]
severity_min: "high"
languages: ["swift"]
buckets: ["error-handling", "architecture"]
enabled: true
---

## Instructions

All domain and application error types must conform to `AppErrorConvertible` so they translate correctly to structured HTTP responses via `AppErrorMiddleware`.

Each error case must map to an `AppError` with:
- **code**: 3-letter prefix + dash + sequential number (e.g., `"PAT-001"`, `"LKP-003"`)
- **bc**: Bounded context (e.g., `"SOCIAL"`)
- **module**: Module path (e.g., `"social-care/registry"`)
- **kind**: Error classification string (e.g., `"InvalidCPF"`, `"TableNotAllowed"`)
- **context**: Raw data for debugging (may contain PII — internal only)
- **safeContext**: Sanitized data safe for external exposure (no PII)
- **observability**: Category, severity, fingerprint, and tags for monitoring
- **http**: HTTP status code (400, 404, 409, 422, etc.)

Flag:
- Error enums that don't conform to `AppErrorConvertible`
- Missing `safeContext` (PII leak risk)
- Error codes not following the prefix-number pattern
- Missing observability configuration

## Examples

### Bad example
```swift
public enum PatientError: Error {
    case invalidCPF(String)
    case notFound(String)
}
// No AppErrorConvertible conformance — will produce generic 500 errors
```

### Good example
```swift
public enum PatientError: Error, Sendable, Equatable {
    case invalidCPF(String)
    case notFound(String)
}

extension PatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/registry"
    private static let codePrefix = "PAT"

    public var asAppError: AppError {
        switch self {
        case .invalidCPF(let cpf):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "CPF informado e invalido.",
                bc: Self.bc, module: Self.module, kind: "InvalidCPF",
                context: ["cpf": .init(cpf)],
                safeContext: ["field": .init("cpf")],
                observability: .init(
                    category: .domainRuleViolation,
                    severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-001"],
                    tags: ["layer": "registry"]
                ),
                http: 422
            )
        case .notFound(let id):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Paciente nao encontrado.",
                bc: Self.bc, module: Self.module, kind: "NotFound",
                context: ["patientId": .init(id)],
                safeContext: ["entity": .init("patient")],
                observability: .init(
                    category: .domainRuleViolation,
                    severity: .info,
                    fingerprint: ["\(Self.codePrefix)-002"],
                    tags: ["layer": "registry"]
                ),
                http: 404
            )
        }
    }
}
```
