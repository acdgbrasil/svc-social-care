import Foundation

public enum NISError: Error, Sendable, Equatable {
    case empty
    case invalidLength(value: String, expected: Int)
}

extension NISError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/nis"
    private static let codePrefix = "NIS"

    public var asAppError: AppError {
        switch self {
        case .empty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O NIS nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyNIS",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "nis"]),
                http: 422
            )
        case .invalidLength(let value, let expected):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "NIS invalido: esperado \(expected) digitos, recebido \(value.count).",
                bc: Self.bc, module: Self.module, kind: "InvalidLength",
                context: ["providedValue": AnySendable(value), "expectedLength": AnySendable(expected)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "nis"]),
                http: 422
            )
        }
    }
}
