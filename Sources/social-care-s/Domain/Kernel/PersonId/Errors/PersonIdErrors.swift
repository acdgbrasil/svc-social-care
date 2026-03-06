import Foundation

/// Erros específicos para o Value Object PersonId.
public enum PIDError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension PIDError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/person-id"
    private static let codePrefix = "PID"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um UUID válido.",
                bc: Self.bc,
                module: Self.module,
                kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(
                    category: .domainRuleViolation,
                    severity: .error,
                    fingerprint: ["\(Self.codePrefix)-001", Self.module],
                    tags: ["domain": "value_object", "vo": "person_id"]
                ),
                http: 422
            )
        }
    }
}
