import Testing
@testable import social_care_s
import Foundation

@Suite("SocialBenefit ValueObject (FP Style - Specification)")
struct SocialBenefitTests {

    private let beneficiaryId = FamilyMemberId()

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        private let beneficiaryId = FamilyMemberId()

        @Test("cria benefício válido")
        func createValid() throws {
            let _ = try SocialBenefit.create(
                benefitName: "Bolsa Família",
                amount: 600.0,
                beneficiaryId: beneficiaryId
            )
        }

        @Test("falha com valor negativo ou zero")
        func failsWithNegativeAmount() {
            #expect(throws: SocialBenefitError.amountInvalid(amount: -10.0)) {
                try SocialBenefit.create(
                    benefitName: "Bolsa Família",
                    amount: -10.0,
                    beneficiaryId: beneficiaryId
                )
            }
        }
        
        @Test("normaliza nome (trim e espaços extras)")
        func normalizeName() throws {
            let benefit = try SocialBenefit.create(
                benefitName: "  Bolsa    Família  ",
                amount: 600.0,
                beneficiaryId: beneficiaryId
            )
            #expect(benefit.benefitName == "Bolsa Família")
        }
    }
}
