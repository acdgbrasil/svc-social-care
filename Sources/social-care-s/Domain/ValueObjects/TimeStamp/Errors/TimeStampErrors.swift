import Foundation

/// Erros específicos para o Value Object TimeStamp.
public enum TimeStampError: Error, Sendable, Equatable {
    case invalidDate(String)
}

extension TimeStampError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/timestamp"
    private static let codePrefix = "TS"

    public var asAppError: AppError {
        switch self {
        case .invalidDate(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é uma data válida.",
                bc: Self.bc,
                module: Self.module,
                kind: "InvalidDate",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(
                    category: .domainRuleViolation,
                    severity: .error,
                    fingerprint: ["\(Self.codePrefix)-001", Self.module],
                    tags: ["domain": "value_object", "vo": "timestamp"]
                ),
                http: 422
            )
        }
    }
}
