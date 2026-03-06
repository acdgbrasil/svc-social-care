import Foundation

public enum CEPError: Error, Sendable, Equatable {
    case empty
    case invalidCharacters(value: String)
    case invalidLength(value: String, expected: Int)
    case outOfKnownPostalRange(value: String)
}

extension CEPError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/cep"
    private static let codePrefix = "CEP"

    public var asAppError: AppError {
        switch self {
        case .empty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O CEP nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyCEP",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "cep"]),
                http: 422
            )
        case .invalidCharacters(let value):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "CEP invalido: utilize apenas digitos e hifen.",
                bc: Self.bc, module: Self.module, kind: "InvalidCharacters",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "cep"]),
                http: 422
            )
        case .invalidLength(let value, let expected):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "CEP invalido: esperado \(expected) digitos, recebido \(value.count).",
                bc: Self.bc, module: Self.module, kind: "InvalidLength",
                context: ["providedValue": AnySendable(value), "expectedLength": AnySendable(expected)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "cep"]),
                http: 422
            )
        case .outOfKnownPostalRange(let value):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "CEP fora das faixas postais conhecidas no Brasil.",
                bc: Self.bc, module: Self.module, kind: "OutOfKnownPostalRange",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "cep"]),
                http: 422
            )
        }
    }
}
