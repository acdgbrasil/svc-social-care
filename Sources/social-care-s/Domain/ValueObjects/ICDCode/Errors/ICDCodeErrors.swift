import Foundation

/// Erros específicos para o Value Object ICDCode.
public enum ICDCodeError: Error, Sendable, Equatable {
    case emptyCidCode
    case invalidCidNumber(value: String, pattern: String = "LNN.N")
}

extension ICDCodeError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/icd-code"
    private static let codePrefix = "ICD"

    public var asAppError: AppError {
        switch self {
        case .emptyCidCode:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O código CID não pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "EmptyCidCode",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "icd_code"]),
                http: 422
            )
        case .invalidCidNumber(let value, let pattern):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O código CID fornecido ('\(value)') é inválido. Esperado padrão similar a \(pattern).",
                bc: Self.bc, module: Self.module, kind: "InvalidCidNumber",
                context: ["providedValue": AnySendable(value), "expectedPattern": AnySendable(pattern)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "icd_code"]),
                http: 422
            )
        }
    }
}
