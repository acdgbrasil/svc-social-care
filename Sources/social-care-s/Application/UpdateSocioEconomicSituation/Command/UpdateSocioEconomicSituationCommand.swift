import Foundation

/// Payload de entrada para a atualização da situação socioeconômica.
struct UpdateSocioEconomicSituationCommand: Sendable {
    struct SocialBenefitDraft: Sendable {
        let benefitName: String
        let amount: Double
        let beneficiaryId: String
    }
    
    struct SituationDraft: Sendable {
        let totalFamilyIncome: Double
        let incomePerCapita: Double
        let receivesSocialBenefit: Bool
        let socialBenefits: [SocialBenefitDraft]
        let mainSourceOfIncome: String
        let hasUnemployed: Bool
    }
    
    let patientId: String
    let situation: SituationDraft
    
    init(patientId: String, situation: SituationDraft) {
        self.patientId = patientId
        self.situation = situation
    }
}
