import Foundation

extension UpdateSocioEconomicSituationService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> UpdateSocioEconomicSituationError {
        if let e = error as? UpdateSocioEconomicSituationError {
            return e
        }
        
        if let e = error as? SocioEconomicSituationError {
            switch e {
            case .inconsistentSocialBenefit: return .inconsistentSocialBenefit
            case .missingSocialBenefits: return .missingSocialBenefits
            case .negativeFamilyIncome(let amount): return .negativeFamilyIncome(amount: amount)
            case .negativeIncomePerCapita(let amount): return .negativeIncomePerCapita(amount: amount)
            case .emptyMainSourceOfIncome: return .emptyMainSourceOfIncome
            case .inconsistentIncomePerCapita(let perCapita, let total): return .inconsistentIncomePerCapita(perCapita: perCapita, total: total)
            }
        }
        
        if let e = error as? SocialBenefitError {
            switch e {
            case .benefitNameEmpty: return .benefitNameEmpty
            case .amountInvalid(let amount): return .amountInvalid(amount: amount)
            }
        }
        
        if let e = error as? SocialBenefitsCollectionError {
            switch e {
            case .benefitsArrayNullOrUndefined: return .persistenceMappingFailure(issues: ["Benefits array is null"])
            case .duplicateBenefitNotAllowed(let name): return .duplicateBenefitNotAllowed(name: name)
            }
        }
        
        if let e = error as? PIDError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
