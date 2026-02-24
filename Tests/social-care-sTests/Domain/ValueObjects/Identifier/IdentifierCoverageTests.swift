import Testing
@testable import social_care_s
import Foundation

@Suite("Identifier ValueObjects Coverage")
struct IdentifierCoverageTests {

    @Test("AppointmentId valida, normaliza e converte erro")
    func appointmentIdCoverage() throws {
        let raw = "  550E8400-E29B-41D4-A716-446655440000  "
        let id = try AppointmentId(raw)
        #expect(id.description == "550e8400-e29b-41d4-a716-446655440000")
        #expect(AppointmentId.brand == "AppointmentId")

        let random = AppointmentId()
        #expect(UUID(uuidString: random.description) != nil)

        #expect(throws: AppointmentIdError.invalidFormat("invalid")) {
            try AppointmentId("  invalid  ")
        }

        let appError = AppointmentIdError.invalidFormat("X").asAppError
        #expect(appError.code == "AI-001")
        #expect(appError.context["providedValue"]?.value as? String == "X")
    }

    @Test("ProfessionalId valida, normaliza e converte erro")
    func professionalIdCoverage() throws {
        let raw = "  550E8400-E29B-41D4-A716-446655440001  "
        let id = try ProfessionalId(raw)
        #expect(id.description == "550e8400-e29b-41d4-a716-446655440001")
        #expect(ProfessionalId.brand == "ProfessionalId")

        let random = ProfessionalId()
        #expect(UUID(uuidString: random.description) != nil)

        #expect(throws: ProfessionalIdError.invalidFormat("invalid")) {
            try ProfessionalId(" invalid ")
        }

        let appError = ProfessionalIdError.invalidFormat("X").asAppError
        #expect(appError.code == "PRI-001")
        #expect(appError.context["providedValue"]?.value as? String == "X")
    }

    @Test("ReferralId valida, normaliza e converte erro")
    func referralIdCoverage() throws {
        let raw = "  550E8400-E29B-41D4-A716-446655440002  "
        let id = try ReferralId(raw)
        #expect(id.description == "550e8400-e29b-41d4-a716-446655440002")
        #expect(ReferralId.brand == "ReferralId")

        let random = ReferralId()
        #expect(UUID(uuidString: random.description) != nil)

        #expect(throws: ReferralIdError.invalidFormat("invalid")) {
            try ReferralId(" invalid ")
        }

        let appError = ReferralIdError.invalidFormat("X").asAppError
        #expect(appError.code == "RI-001")
        #expect(appError.context["providedValue"]?.value as? String == "X")
    }

    @Test("ViolationReportId valida, normaliza e converte erro")
    func violationReportIdCoverage() throws {
        let raw = "  550E8400-E29B-41D4-A716-446655440003  "
        let id = try ViolationReportId(raw)
        #expect(id.description == "550e8400-e29b-41d4-a716-446655440003")
        #expect(ViolationReportId.brand == "ViolationReportId")

        let random = ViolationReportId()
        #expect(UUID(uuidString: random.description) != nil)

        #expect(throws: ViolationReportIdError.invalidFormat("invalid")) {
            try ViolationReportId(" invalid ")
        }

        let appError = ViolationReportIdError.invalidFormat("X").asAppError
        #expect(appError.code == "VRI-001")
        #expect(appError.context["providedValue"]?.value as? String == "X")
    }

    @Test("PatientId valida, normaliza e converte erro")
    func patientIdCoverage() throws {
        let raw = "  550E8400-E29B-41D4-A716-446655440004  "
        let id = try PatientId(raw)
        #expect(id.description == "550e8400-e29b-41d4-a716-446655440004")
        #expect(PatientId.brand == "PatientId")

        let random = PatientId()
        #expect(UUID(uuidString: random.description) != nil)

        #expect(throws: PatientIdError.invalidFormat("invalid")) {
            try PatientId(" invalid ")
        }

        let appError = PatientIdError.invalidFormat("X").asAppError
        #expect(appError.code == "PAI-001")
        #expect(appError.context["providedValue"]?.value as? String == "X")
    }

    @Test("Helpers legados AIE/PRIE/RIE/VRIE geram AppError consistente")
    func legacyHelperCoverage() {
        #expect(AIE.invalidFormat("x").code == "AI-001")
        #expect(PRIE.invalidFormat("x").code == "PRI-001")
        #expect(RIE.invalidFormat("x").code == "RI-001")
        #expect(VRIE.invalidFormat("x").code == "VRI-001")

        #expect(AIE.invalidFormat("x").safeContext["providedValue"]?.value as? String == "x")
        #expect(PRIE.invalidFormat("x").safeContext["providedValue"]?.value as? String == "x")
        #expect(RIE.invalidFormat("x").safeContext["providedValue"]?.value as? String == "x")
        #expect(VRIE.invalidFormat("x").safeContext["providedValue"]?.value as? String == "x")
    }
}
