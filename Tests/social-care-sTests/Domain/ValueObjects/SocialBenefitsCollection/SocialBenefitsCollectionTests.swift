import Testing
@testable import social_care_s
import Foundation

@Suite("SocialBenefitsCollection ValueObject")
struct SocialBenefitsCollectionTests {

    @Test("Valida duplicatas na coleção")
    func validateDuplicates() throws {
        let beneficiaryId = PersonId()
        let benefit = try SocialBenefit(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
        #expect(throws: SocialBenefitsCollectionError.duplicateBenefitNotAllowed(name: "A")) {
            try SocialBenefitsCollection([benefit, benefit])
        }
    }

    @Test("Valida cálculos de agregação")
    func aggregations() throws {
        let beneficiaryId = PersonId()
        let b1 = try SocialBenefit(benefitName: "A", amount: 100, beneficiaryId: beneficiaryId)
        let b2 = try SocialBenefit(benefitName: "B", amount: 200, beneficiaryId: beneficiaryId)
        let col = try SocialBenefitsCollection([b1, b2])
        
        #expect(col.totalAmount == 300.0)
        #expect(col.count == 2)
    }

    @Test("Valida conversão de SocialBenefitsCollectionError para AppError")
    func errorConversion() {
        #expect(SocialBenefitsCollectionError.benefitsArrayNullOrUndefined.asAppError.code == "SBC-001")
        #expect(SocialBenefitsCollectionError.duplicateBenefitNotAllowed(name: "A").asAppError.code == "SBC-002")
    }
}
