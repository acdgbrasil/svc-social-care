import Testing
@testable import social_care_s
import Foundation

@Suite("SocioEconomicSituation ValueObject")
struct SocioEconomicSituationTests {

    @Test("Valida consistência de benefícios")
    func validateMissingBenefits() throws {
        let emptyCol = try SocialBenefitsCollection([])
        #expect(throws: SocioEconomicSituationError.missingSocialBenefits) {
            try SocioEconomicSituation(
                totalFamilyIncome: 1000,
                incomePerCapita: 500,
                receivesSocialBenefit: true,
                socialBenefits: emptyCol,
                mainSourceOfIncome: "Work",
                hasUnemployed: false
            )
        }
    }

    @Test("Valida inconsistência de benefícios (receives=false)")
    func validateInconsistentBenefits() throws {
        let beneficiaryId = PersonId()
        let benefit = try SocialBenefit(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
        let notEmptyCol = try SocialBenefitsCollection([benefit])
        
        #expect(throws: SocioEconomicSituationError.inconsistentSocialBenefit) {
            try SocioEconomicSituation(
                totalFamilyIncome: 1000,
                incomePerCapita: 500,
                receivesSocialBenefit: false,
                socialBenefits: notEmptyCol,
                mainSourceOfIncome: "Work",
                hasUnemployed: false
            )
        }
    }

    @Test("Valida rendas negativas e inconsistências")
    func validateNegativeIncome() throws {
        let emptyCol = try SocialBenefitsCollection([])
        #expect(throws: SocioEconomicSituationError.negativeFamilyIncome(amount: -1)) {
            try SocioEconomicSituation(totalFamilyIncome: -1, incomePerCapita: 0, receivesSocialBenefit: false, socialBenefits: emptyCol, mainSourceOfIncome: "Work", hasUnemployed: false)
        }
        
        #expect(throws: SocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: 1500, total: 1000)) {
            try SocioEconomicSituation(totalFamilyIncome: 1000, incomePerCapita: 1500, receivesSocialBenefit: false, socialBenefits: emptyCol, mainSourceOfIncome: "Work", hasUnemployed: false)
        }
    }

    @Test("Valida renda per capita negativa e fonte de renda vazia")
    func validateNegativePerCapitaAndEmptySource() throws {
        let emptyCol = try SocialBenefitsCollection([])

        #expect(throws: SocioEconomicSituationError.negativeIncomePerCapita(amount: -1)) {
            try SocioEconomicSituation(
                totalFamilyIncome: 1000,
                incomePerCapita: -1,
                receivesSocialBenefit: false,
                socialBenefits: emptyCol,
                mainSourceOfIncome: "Work",
                hasUnemployed: false
            )
        }

        #expect(throws: SocioEconomicSituationError.emptyMainSourceOfIncome) {
            try SocioEconomicSituation(
                totalFamilyIncome: 1000,
                incomePerCapita: 500,
                receivesSocialBenefit: false,
                socialBenefits: emptyCol,
                mainSourceOfIncome: "   ",
                hasUnemployed: false
            )
        }
    }

    @Test("Cria situação válida e normaliza fonte de renda")
    func createValidSituationAndNormalizeSource() throws {
        let beneficiaryId = PersonId()
        let benefit = try SocialBenefit(benefitName: "Auxílio", amount: 100, beneficiaryId: beneficiaryId)
        let benefits = try SocialBenefitsCollection([benefit])

        let sut = try SocioEconomicSituation(
            totalFamilyIncome: 2000,
            incomePerCapita: 500,
            receivesSocialBenefit: true,
            socialBenefits: benefits,
            mainSourceOfIncome: "  Trabalho informal  ",
            hasUnemployed: true
        )

        #expect(sut.mainSourceOfIncome == "Trabalho informal")
        #expect(sut.receivesSocialBenefit)
        #expect(!sut.socialBenefits.isEmpty)
        #expect(sut.hasUnemployed)
    }

    @Test("Valida conversão de SocioEconomicSituationError para AppError")
    func errorConversion() {
        #expect(SocioEconomicSituationError.inconsistentSocialBenefit.asAppError.code == "SES-001")
        #expect(SocioEconomicSituationError.missingSocialBenefits.asAppError.code == "SES-002")
        #expect(SocioEconomicSituationError.negativeFamilyIncome(amount: 1).asAppError.code == "SES-003")
        #expect(SocioEconomicSituationError.negativeIncomePerCapita(amount: 1).asAppError.code == "SES-004")
        #expect(SocioEconomicSituationError.emptyMainSourceOfIncome.asAppError.code == "SES-005")
        #expect(SocioEconomicSituationError.inconsistentIncomePerCapita(perCapita: 1, total: 1).asAppError.code == "SES-006")
    }
}
