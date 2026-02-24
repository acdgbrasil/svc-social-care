import Foundation

/// Erros específicos para o Value Object FamilyMemberId.
public enum FamilyMemberIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension FamilyMemberIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/family-member-id"
    private static let codePrefix = "FMI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de membro familiar válido.",
                bc: Self.bc,
                module: Self.module,
                kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(
                    category: .domainRuleViolation,
                    severity: .error,
                    fingerprint: ["\(Self.codePrefix)-001", Self.module],
                    tags: ["domain": "value_object", "vo": "family_member_id"]
                ),
                http: 422
            )
        }
    }
}
