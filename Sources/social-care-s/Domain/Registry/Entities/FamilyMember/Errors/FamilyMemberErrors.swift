import Foundation

/// Erros específicos para a Entidade FamilyMember.
public enum FamilyMemberError: Error, Sendable, Equatable {
    case missingPerson
    case invalidRelationship
}

extension FamilyMemberError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/family-member"
    private static let codePrefix = "FM"

    public var asAppError: AppError {
        switch self {
        case .missingPerson:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Um membro familiar deve estar associado a uma pessoa (PersonId).",
                bc: Self.bc, module: Self.module, kind: "MissingPerson",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["entity": "family_member"]),
                http: 422
            )
        case .invalidRelationship:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O parentesco/relacionamento deve ser informado.",
                bc: Self.bc, module: Self.module, kind: "InvalidRelationship",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["entity": "family_member"]),
                http: 422
            )
        }
    }
}
