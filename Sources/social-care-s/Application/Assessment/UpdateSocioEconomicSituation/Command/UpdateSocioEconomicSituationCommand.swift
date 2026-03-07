import Foundation

/// Payload de entrada para a atualização da situação socioeconômica.
public struct UpdateSocioEconomicSituationCommand: Command {
    public struct SocialBenefitDraft: Sendable {
        let benefitName: String
        let amount: Double
        let beneficiaryId: String
        
        public init(benefitName: String, amount: Double, beneficiaryId: String) {
            self.benefitName = benefitName
            self.amount = amount
            self.beneficiaryId = beneficiaryId
        }
    }
    
    public struct SituationDraft: Sendable {
        let totalFamilyIncome: Double
        let incomePerCapita: Double
        let receivesSocialBenefit: Bool
        let socialBenefits: [SocialBenefitDraft]
        let mainSourceOfIncome: String
        let hasUnemployed: Bool
        
        public init(totalFamilyIncome: Double, incomePerCapita: Double, receivesSocialBenefit: Bool, socialBenefits: [SocialBenefitDraft], mainSourceOfIncome: String, hasUnemployed: Bool) {
            self.totalFamilyIncome = totalFamilyIncome
            self.incomePerCapita = incomePerCapita
            self.receivesSocialBenefit = receivesSocialBenefit
            self.socialBenefits = socialBenefits
            self.mainSourceOfIncome = mainSourceOfIncome
            self.hasUnemployed = hasUnemployed
        }
    }
    
    public let patientId: String
    public let situation: SituationDraft
    public let actorId: String

    public init(patientId: String, situation: SituationDraft, actorId: String) {
        self.patientId = patientId
        self.situation = situation
        self.actorId = actorId
    }
}
