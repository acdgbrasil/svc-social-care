import Testing
@testable import social_care_s
import Foundation

@Suite("SocioEconomicSituation ValueObject (FP Style - Specification)")
struct SocioEconomicSituationTests {

    private let beneficiaryId = FamilyMemberId()

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let beneficiaryId = FamilyMemberId()

        @Test("create valida consistência de benefícios (receives=true, collection=empty deve falhar)")
        func validateMissingBenefits() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            #expect(throws: SocioEconomicSituationError.missingSocialBenefits) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: 1000,
                    incomePerCapita: 500,
                    receivesSocialBenefit: true,
                    socialBenefits: emptyCol,
                    mainSourceOfIncome: "Work",
                    hasUnemployed: false
                )
            }
        }

        @Test("create valida inconsistência (receives=false, collection=notEmpty deve falhar)")
        func validateInconsistentBenefits() throws {
            let benefit = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
            let notEmptyCol = try SocialBenefitsCollection.create([benefit])
            
            #expect(throws: SocioEconomicSituationError.inconsistentSocialBenefit) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: 1000,
                    incomePerCapita: 500,
                    receivesSocialBenefit: false,
                    socialBenefits: notEmptyCol,
                    mainSourceOfIncome: "Work",
                    hasUnemployed: false
                )
            }
        }

        @Test("create valida renda negativa")
        func validateNegativeIncome() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            #expect(throws: SocioEconomicSituationError.negativeFamilyIncome(amount: -1)) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: -1,
                    incomePerCapita: 0,
                    receivesSocialBenefit: false,
                    socialBenefits: emptyCol,
                    mainSourceOfIncome: "Work",
                    hasUnemployed: false
                )
            }
        }

        @Test("create valida incomePerCapita maior que renda total")
        func validateIncomeInconsistency() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            #expect(throws: SocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: 1500, total: 1000)) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: 1000,
                    incomePerCapita: 1500,
                    receivesSocialBenefit: false,
                    socialBenefits: emptyCol,
                    mainSourceOfIncome: "Work",
                    hasUnemployed: false
                )
            }
        }

        @Test("create valida incomePerCapita negativa")
        func validateNegativePerCapita() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            #expect(throws: SocioEconomicSituationError.negativeIncomePerCapita(amount: -1)) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: 1000,
                    incomePerCapita: -1,
                    receivesSocialBenefit: false,
                    socialBenefits: emptyCol,
                    mainSourceOfIncome: "Work",
                    hasUnemployed: false
                )
            }
        }

        @Test("create valida fonte de renda vazia")
        func validateEmptySource() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            #expect(throws: SocioEconomicSituationError.emptyMainSourceOfIncome) {
                try SocioEconomicSituation.create(
                    totalFamilyIncome: 1000,
                    incomePerCapita: 500,
                    receivesSocialBenefit: false,
                    socialBenefits: emptyCol,
                    mainSourceOfIncome: "   ",
                    hasUnemployed: false
                )
            }
        }

        @Test("aceita renda per capita igual à total (limite)")
        func validateBoundaryIncome() throws {
            let emptyCol = try SocialBenefitsCollection.create([])
            let _ = try SocioEconomicSituation.create(
                totalFamilyIncome: 1000,
                incomePerCapita: 1000,
                receivesSocialBenefit: false,
                socialBenefits: emptyCol,
                mainSourceOfIncome: "Work",
                hasUnemployed: false
            )
        }
    }
}
