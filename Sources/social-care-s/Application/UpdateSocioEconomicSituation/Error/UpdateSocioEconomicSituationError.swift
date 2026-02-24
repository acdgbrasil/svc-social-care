import Foundation

/// Erros específicos para o caso de uso de atualização da situação socioeconômica.
enum UpdateSocioEconomicSituationError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case inconsistentSocialBenefit
    case missingSocialBenefits
    case negativeFamilyIncome(amount: Double)
    case negativeIncomePerCapita(amount: Double)
    case emptyMainSourceOfIncome
    case inconsistentIncomePerCapita(perCapita: Double, total: Double)
    case benefitNameEmpty
    case amountInvalid(amount: Double)
    case duplicateBenefitNotAllowed(name: String)
    case persistenceMappingFailure(issues: [String])
}

extension UpdateSocioEconomicSituationError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "USES"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .inconsistentSocialBenefit:
            return appFailure("003", kind: "InconsistentSocialBenefit", "Inconsistência nos benefícios sociais informados.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .missingSocialBenefits:
            return appFailure("004", kind: "MissingSocialBenefits", "Benefícios sociais obrigatórios não informados.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .negativeFamilyIncome(let amount):
            return appFailure("005", kind: "NegativeFamilyIncome", "Renda familiar total (\(amount)) não pode ser negativa.", category: .domainRuleViolation, severity: .error, http: 422)
        case .negativeIncomePerCapita(let amount):
            return appFailure("006", kind: "NegativeIncomePerCapita", "Renda per capita (\(amount)) não pode ser negativa.", category: .domainRuleViolation, severity: .error, http: 422)
        case .emptyMainSourceOfIncome:
            return appFailure("007", kind: "EmptyMainSourceOfIncome", "A principal fonte de renda é obrigatória.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .inconsistentIncomePerCapita(let perCapita, let total):
            return appFailure("008", kind: "InconsistentIncomePerCapita", "Renda per capita (\(perCapita)) não pode ser maior que a total (\(total)).", category: .domainRuleViolation, severity: .error, http: 422)
        case .benefitNameEmpty:
            return appFailure("009", kind: "BenefitNameEmpty", "O nome do benefício social não pode ser vazio.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .amountInvalid(let amount):
            return appFailure("010", kind: "AmountInvalid", "Valor de benefício inválido: \(amount).", category: .domainRuleViolation, severity: .warning, http: 422)
        case .duplicateBenefitNotAllowed(let name):
            return appFailure("011", kind: "DuplicateBenefitNotAllowed", "Benefício duplicado: \(name).", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("012", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar a situação socioeconômica.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_socioeconomic_situation"]),
            http: http
        )
    }
}
