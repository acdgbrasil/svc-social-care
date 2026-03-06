import Foundation

/// Erros específicos para o Value Object SocioEconomicSituation.
public enum SocioEconomicSituationError: Error, Sendable, Equatable {
    case inconsistentSocialBenefit
    case missingSocialBenefits
    case negativeFamilyIncome(amount: Double)
    case negativeIncomePerCapita(amount: Double)
    case emptyMainSourceOfIncome
    case inconsistentIncomePerCapita(perCapita: Double, total: Double)
}

extension SocioEconomicSituationError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/socio-economic-situation"
    private static let codePrefix = "SES"

    public var asAppError: AppError {
        switch self {
        case .inconsistentSocialBenefit:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Inconsistência: Indicado que não recebe benefícios, mas a lista de benefícios não está vazia.",
                bc: Self.bc, module: Self.module, kind: "InconsistentSocialBenefit",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        case .missingSocialBenefits:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Inconsistência: Indicado que recebe benefícios, mas a lista de benefícios está vazia.",
                bc: Self.bc, module: Self.module, kind: "MissingSocialBenefits",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        case .negativeFamilyIncome(let amount):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "A renda familiar total (\(amount)) não pode ser negativa.",
                bc: Self.bc, module: Self.module, kind: "NegativeFamilyIncome",
                context: ["totalFamilyIncome": AnySendable(amount)],
                safeContext: ["totalFamilyIncome": AnySendable(amount)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        case .negativeIncomePerCapita(let amount):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "A renda per capita (\(amount)) não pode ser negativa.",
                bc: Self.bc, module: Self.module, kind: "NegativeIncomePerCapita",
                context: ["incomePerCapita": AnySendable(amount)],
                safeContext: ["incomePerCapita": AnySendable(amount)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        case .emptyMainSourceOfIncome:
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "A principal fonte de renda deve ser informada.",
                bc: Self.bc, module: Self.module, kind: "EmptyMainSourceOfIncome",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        case .inconsistentIncomePerCapita(let perCapita, let total):
            return AppError(
                code: "\(Self.codePrefix)-006",
                message: "A renda per capita (\(perCapita)) não pode ser maior que a renda familiar total (\(total)).",
                bc: Self.bc, module: Self.module, kind: "InconsistentIncomePerCapita",
                context: ["incomePerCapita": AnySendable(perCapita), "totalFamilyIncome": AnySendable(total)],
                safeContext: ["incomePerCapita": AnySendable(perCapita), "totalFamilyIncome": AnySendable(total)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-006"], tags: ["vo": "socio_economic_situation"]),
                http: 422
            )
        }
    }
}
