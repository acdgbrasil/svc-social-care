import Foundation

/// Erros específicos para o Value Object SocialBenefitsCollection.
public enum SocialBenefitsCollectionError: Error, Sendable, Equatable {
    case benefitsArrayNullOrUndefined
    case duplicateBenefitNotAllowed(name: String)
}

extension SocialBenefitsCollectionError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/social-benefits-collection"
    private static let codePrefix = "SBC"

    public var asAppError: AppError {
        switch self {
        case .benefitsArrayNullOrUndefined:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A lista de benefícios não pode ser nula.",
                bc: Self.bc, module: Self.module, kind: "BenefitsArrayNullOrUndefined",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "social_benefits_collection"]),
                http: 422
            )
        case .duplicateBenefitNotAllowed(let name):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Não são permitidos benefícios duplicados com o mesmo nome: \(name).",
                bc: Self.bc, module: Self.module, kind: "DuplicateBenefitNotAllowed",
                context: ["benefitName": AnySendable(name)],
                safeContext: ["benefitName": AnySendable(name)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "social_benefits_collection"]),
                http: 422
            )
        }
    }
}
