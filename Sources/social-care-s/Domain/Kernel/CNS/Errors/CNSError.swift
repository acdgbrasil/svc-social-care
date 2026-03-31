import Foundation

public enum CNSError: Error, Sendable, Equatable {
    case empty
    case invalidLength(value: String, expected: Int)
    case invalidFirstDigit(value: String, digit: Int)
    case invalidNumber(value: String)
    case invalidCheckDigit(value: String)
}

extension CNSError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/cns"
    private static let codePrefix = "CNS"

    public var asAppError: AppError {
        switch self {
        case .empty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O numero do CNS nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyCNS",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "cns"]),
                http: 422
            )
        case .invalidLength(let value, let expected):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "CNS invalido: esperado \(expected) digitos, recebido \(value.count).",
                bc: Self.bc, module: Self.module, kind: "InvalidLength",
                context: ["providedValue": AnySendable(value), "expectedLength": AnySendable(expected)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "cns"]),
                http: 422
            )
        case .invalidFirstDigit(let value, let digit):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "CNS invalido: primeiro digito \(digit) nao e permitido (esperado 1, 2, 7, 8 ou 9).",
                bc: Self.bc, module: Self.module, kind: "InvalidFirstDigit",
                context: ["providedValue": AnySendable(value), "firstDigit": AnySendable(digit)],
                safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "cns"]),
                http: 422
            )
        case .invalidNumber(let value):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "Numero CNS invalido: \(value).",
                bc: Self.bc, module: Self.module, kind: "InvalidNumber",
                context: ["providedValue": AnySendable(value)],
                safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "cns"]),
                http: 422
            )
        case .invalidCheckDigit(let value):
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "CNS invalido: digito verificador incorreto.",
                bc: Self.bc, module: Self.module, kind: "InvalidCheckDigit",
                context: ["providedValue": AnySendable(value)],
                safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "cns"]),
                http: 422
            )
        }
    }
}
