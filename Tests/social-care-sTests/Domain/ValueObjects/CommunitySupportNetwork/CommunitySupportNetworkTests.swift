import Testing
@testable import social_care_s
import Foundation

@Suite("CommunitySupportNetwork ValueObject (FP Style - Specification)")
struct CommunitySupportNetworkTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {

        @Test("create valida conflitos (apenas whitespace deve falhar)")
        func validateWhitespaceConflicts() {
            #expect(throws: CommunitySupportNetworkError.familyConflictsWhitespace) {
                try CommunitySupportNetwork.create(
                    hasRelativeSupport: true,
                    hasNeighborSupport: true,
                    familyConflicts: "   ",
                    patientParticipatesInGroups: true,
                    familyParticipatesInGroups: true,
                    patientHasAccessToLeisure: true,
                    facesDiscrimination: false
                )
            }
        }

        @Test("create normaliza (trim)")
        func normalizeTrim() throws {
            let csn = try CommunitySupportNetwork.create(
                hasRelativeSupport: true,
                hasNeighborSupport: true,
                familyConflicts: "  Test  ",
                patientParticipatesInGroups: true,
                familyParticipatesInGroups: true,
                patientHasAccessToLeisure: true,
                facesDiscrimination: false
            )
            
            #expect(csn.familyConflicts == "Test")
        }
    }
}
