import Testing
@testable import social_care_s
import Foundation

@Suite("SocialBenefitsCollection ValueObject (FP Style - Specification)")
struct SocialBenefitsCollectionTests {

    private let beneficiaryId = FamilyMemberId()

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let beneficiaryId = FamilyMemberId()

        @Test("create valida duplicatas")
        func validateDuplicates() throws {
            let benefit = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
            #expect(throws: SocialBenefitsCollectionError.duplicateBenefitNotAllowed(name: "A")) {
                try SocialBenefitsCollection.create([benefit, benefit])
            }
        }

        @Test("create aceita array vazio")
        func acceptEmptyArray() throws {
            let col = try SocialBenefitsCollection.create([])
            #expect(col.isEmpty == true)
        }
    }

    @Suite("2. Helpers e Agregações")
    struct HelpersAndAggregations {
        private let beneficiaryId = FamilyMemberId()

        @Test("totalAmount calcula soma corretamente")
        func totalAmountCalculation() throws {
            let b1 = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
            let b2 = try SocialBenefit.create(benefitName: "B", amount: 200, beneficiaryId: beneficiaryId)
            let col = try SocialBenefitsCollection.create([b1, b2])
            
            #expect(col.totalAmount == 300.0)
        }

        @Test("count retorna tamanho correto")
        func countProperty() throws {
            let b1 = try SocialBenefit.create(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
            let col = try SocialBenefitsCollection.create([b1])
            #expect(col.count == 1)
        }
    }
}
