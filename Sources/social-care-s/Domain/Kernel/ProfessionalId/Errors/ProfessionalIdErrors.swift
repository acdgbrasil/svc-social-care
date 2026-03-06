import Foundation

public enum ProfessionalIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension ProfessionalIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/professional-id"
    private static let codePrefix = "PRI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de profissional válido.",
                bc: Self.bc, module: Self.module, kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "professional_id"]),
                http: 422
            )
        }
    }
}
