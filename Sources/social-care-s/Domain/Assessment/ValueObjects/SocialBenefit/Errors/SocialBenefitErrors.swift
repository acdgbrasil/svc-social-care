import Foundation

/// Erros específicos para o Value Object SocialBenefit.
public enum SocialBenefitError: Error, Sendable, Equatable {
    case benefitNameEmpty
    case amountInvalid(amount: Double)
}

extension SocialBenefitError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/social-benefit"
    private static let codePrefix = "SB"

    public var asAppError: AppError {
        switch self {
        case .benefitNameEmpty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O nome do benefício não pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "BenefitNameEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "social_benefit"]),
                http: 422
            )
        case .amountInvalid(let amount):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O valor do benefício (\(amount)) deve ser maior que zero.",
                bc: Self.bc, module: Self.module, kind: "AmountInvalid",
                context: ["amount": AnySendable(amount)],
                safeContext: ["amount": AnySendable(amount)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "social_benefit"]),
                http: 422
            )
        }
    }
}
