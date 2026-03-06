import Foundation

public enum CPFError: Error, Sendable, Equatable {
    case empty
    case invalidCharacters(value: String)
    case invalidLength(value: String, expected: Int)
    case repeatedDigits(value: String)
    case invalidCheckDigits(value: String)
}

extension CPFError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/cpf"
    private static let codePrefix = "CPF"

    public var asAppError: AppError {
        switch self {
        case .empty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O CPF nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyCPF",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "cpf"]),
                http: 422
            )
        case .invalidCharacters(let value):
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "CPF invalido: utilize apenas digitos, pontos e hifen.",
                bc: Self.bc, module: Self.module, kind: "InvalidCharacters",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "cpf"]),
                http: 422
            )
        case .invalidLength(let value, let expected):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "CPF invalido: esperado \(expected) digitos, recebido \(value.count).",
                bc: Self.bc, module: Self.module, kind: "InvalidLength",
                context: ["providedValue": AnySendable(value), "expectedLength": AnySendable(expected)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "cpf"]),
                http: 422
            )
        case .repeatedDigits(let value):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "CPF invalido: todos os digitos sao iguais.",
                bc: Self.bc, module: Self.module, kind: "RepeatedDigits",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "cpf"]),
                http: 422
            )
        case .invalidCheckDigits(let value):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "CPF invalido: digitos verificadores inconsistentes.",
                bc: Self.bc, module: Self.module, kind: "InvalidCheckDigits",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "cpf"]),
                http: 422
            )
        }
    }
}
