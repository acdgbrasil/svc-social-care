import Testing
@testable import social_care_s
import Foundation

@Suite("SocialBenefit ValueObject (FP Style - Specification)")
struct SocialBenefitTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {
        @Test("cria benefício válido")
        func createValid() throws {
            let beneficiaryId = PersonId()
            let _ = try SocialBenefit(
                benefitName: "Bolsa Família",
                amount: 600.0,
                beneficiaryId: beneficiaryId
            )
        }

        @Test("falha com valor negativo ou zero")
        func failsWithNegativeAmount() {
            let beneficiaryId = PersonId()
            #expect(throws: SocialBenefitError.amountInvalid(amount: -10.0)) {
                try SocialBenefit(
                    benefitName: "Bolsa Família",
                    amount: -10.0,
                    beneficiaryId: beneficiaryId
                )
            }
        }
        
        @Test("normaliza nome (trim e espaços extras)")
        func normalizeName() throws {
            let beneficiaryId = PersonId()
            let benefit = try SocialBenefit(
                benefitName: "  Bolsa    Família  ",
                amount: 600.0,
                beneficiaryId: beneficiaryId
            )
            #expect(benefit.benefitName == "Bolsa Família")
        }
    }

    @Suite("2. Erros e Conversão")
    struct ErrorHandling {
        @Test("Valida conversão de SocialBenefitError para AppError")
        func errorConversion() {
            #expect(SocialBenefitError.benefitNameEmpty.asAppError.code == "SB-001")
            #expect(SocialBenefitError.amountInvalid(amount: 1).asAppError.code == "SB-002")
        }
    }
}
