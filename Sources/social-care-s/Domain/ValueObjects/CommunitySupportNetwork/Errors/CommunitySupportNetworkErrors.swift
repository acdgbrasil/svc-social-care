import Foundation

/// Erros específicos para o Value Object CommunitySupportNetwork.
public enum CommunitySupportNetworkError: Error, Sendable, Equatable {
    case familyConflictsWhitespace
    case familyConflictsTooLong(limit: Int)
}

extension CommunitySupportNetworkError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/community-support-network"
    private static let codePrefix = "CSN"

    public var asAppError: AppError {
        switch self {
        case .familyConflictsWhitespace:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O campo de conflitos familiares não pode conter apenas espaços em branco.",
                bc: Self.bc, module: Self.module, kind: "FamilyConflictsWhitespace",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "csn"]),
                http: 422
            )
        case .familyConflictsTooLong(let limit):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O relato de conflitos familiares excede o limite de \(limit) caracteres.",
                bc: Self.bc, module: Self.module, kind: "FamilyConflictsTooLong",
                context: ["limit": AnySendable(limit)], safeContext: ["limit": AnySendable(limit)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "csn"]),
                http: 422
            )
        }
    }
}
