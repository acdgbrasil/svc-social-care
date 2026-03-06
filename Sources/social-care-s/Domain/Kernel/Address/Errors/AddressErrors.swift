import Foundation

public enum AddressError: Error, Sendable, Equatable {
    case invalidCep(value: String)
    case stateRequired
    case invalidState(value: String)
    case cityRequired
}

extension AddressError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/address"
    private static let codePrefix = "ADR"

    public var asAppError: AppError {
        switch self {
        case .invalidCep(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "CEP do endereco invalido.",
                bc: Self.bc, module: Self.module, kind: "InvalidCep",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "address"]),
                http: 422
            )
        case .stateRequired:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "UF do endereco e obrigatoria.",
                bc: Self.bc, module: Self.module, kind: "StateRequired",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "address"]),
                http: 422
            )
        case .invalidState(let value):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "UF do endereco invalida: '\(value)'.",
                bc: Self.bc, module: Self.module, kind: "InvalidState",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "address"]),
                http: 422
            )
        case .cityRequired:
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "Cidade do endereco e obrigatoria.",
                bc: Self.bc, module: Self.module, kind: "CityRequired",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "address"]),
                http: 422
            )
        }
    }
}
