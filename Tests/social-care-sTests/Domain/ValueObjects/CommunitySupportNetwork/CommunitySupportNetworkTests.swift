import Testing
@testable import social_care_s
import Foundation

@Suite("CommunitySupportNetwork ValueObject")
struct CommunitySupportNetworkTests {

    @Test("Valida conflitos familiares (apenas whitespace)")
    func validateWhitespace() {
        #expect(throws: CommunitySupportNetworkError.familyConflictsWhitespace) {
            try CommunitySupportNetwork(hasRelativeSupport: true, hasNeighborSupport: true, familyConflicts: "   ", patientParticipatesInGroups: true, familyParticipatesInGroups: true, patientHasAccessToLeisure: true, facesDiscrimination: false)
        }
    }

    @Test("Valida conversão de CommunitySupportNetworkError para AppError")
    func errorConversion() {
        #expect(CommunitySupportNetworkError.familyConflictsWhitespace.asAppError.code == "CSN-001")
        #expect(CommunitySupportNetworkError.familyConflictsTooLong(limit: 300).asAppError.code == "CSN-002")
    }
}
