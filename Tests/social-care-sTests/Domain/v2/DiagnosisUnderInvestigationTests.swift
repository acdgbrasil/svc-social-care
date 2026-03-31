import Testing
@testable import social_care_s
import Foundation

@Suite("Diagnosis Under Investigation Tests")
struct DiagnosisUnderInvestigationTests {

    @Test("ICDCode.underInvestigation deve ser Z03.9")
    func icdCodeConstant() {
        #expect(ICDCode.underInvestigation.value == "Z03.9")
        #expect(ICDCode.underInvestigation.normalized == "Z039")
    }

    @Test("Diagnosis.underInvestigation factory deve criar diagnostico valido")
    func factoryMethod() throws {
        let now = TimeStamp.now
        let diagnosis = try Diagnosis.underInvestigation(date: now, now: now)

        #expect(diagnosis.id == ICDCode.underInvestigation)
        #expect(diagnosis.description == "Diagnostico em investigacao")
        #expect(diagnosis.date == now)
    }

    @Test("Diagnosis.underInvestigation nao aceita data futura")
    func factoryRejectsFutureDate() throws {
        let now = try TimeStamp(Date())
        let future = try TimeStamp(Date().addingTimeInterval(86400 * 30))

        #expect(throws: DiagnosisError.self) {
            try Diagnosis.underInvestigation(date: future, now: now)
        }
    }

    @Test("ICDCode.underInvestigation e equivalente a Z039")
    func equivalence() throws {
        let manual = try ICDCode("Z039")
        #expect(ICDCode.underInvestigation.isEquivalent(to: manual))
    }
}
