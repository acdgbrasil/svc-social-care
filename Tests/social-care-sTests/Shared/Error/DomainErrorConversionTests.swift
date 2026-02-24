import Testing
@testable import social_care_s
import Foundation

@Suite("Domain Error Conversion Tests")
struct DomainErrorConversionTests {

    @Test("ID Errors Conversion")
    func idErrorConversion() {
        #expect(PatientIdError.invalidFormat("X").asAppError.code == "PAI-001")
        #expect(AppointmentIdError.invalidFormat("X").asAppError.code == "AI-001")
        #expect(ViolationReportIdError.invalidFormat("X").asAppError.code == "VRI-001")
        #expect(ReferralIdError.invalidFormat("X").asAppError.code == "RI-001")
        #expect(ProfessionalIdError.invalidFormat("X").asAppError.code == "PRI-001")
        #expect(PIDError.invalidFormat("X").asAppError.code == "PID-001")
    }

    @Test("TimeStamp and ICDCode Errors Conversion")
    func utilityErrorConversion() {
        #expect(TimeStampError.invalidDate("X").asAppError.code == "TS-001")
        #expect(ICDCodeError.emptyCidCode.asAppError.code == "ICD-001")
        #expect(ICDCodeError.invalidCidNumber(value: "X").asAppError.code == "ICD-002")
    }
}
