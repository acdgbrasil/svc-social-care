import Testing
import Foundation
@testable import social_care_s

@Suite("Patient Aggregate — Waitlist Lifecycle")
struct PatientWaitlistTests {

    private static let actorId = "test-actor"

    // MARK: - Admit Happy Path

    @Test("Deve admitir paciente waitlisted com sucesso")
    func admitWaitlistedPatient() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        try patient.admit(actorId: Self.actorId)

        #expect(patient.status == .active)
    }

    @Test("Deve registrar PatientAdmittedEvent ao admitir")
    func admitRecordsEvent() throws {
        var patient = try PatientFixture.createMinimal()
        let versionBefore = patient.version
        patient.clearEvents()

        try patient.admit(actorId: Self.actorId)

        let events = patient.uncommittedEvents
        let admitEvent = events.compactMap { $0 as? PatientAdmittedEvent }.first
        #expect(admitEvent != nil)
        #expect(admitEvent?.patientId == patient.id.description)
        #expect(admitEvent?.personId == patient.personId.description)
        #expect(admitEvent?.actorId == Self.actorId)
        #expect(patient.version > versionBefore)
    }

    // MARK: - Admit Error Cases

    @Test("Deve falhar ao admitir paciente ja ativo")
    func admitAlreadyActiveThrows() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")

        #expect(throws: PatientError.alreadyActive) {
            try patient.admit(actorId: Self.actorId)
        }
    }

    @Test("Deve falhar ao admitir paciente desligado")
    func admitDischargedThrows() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: "setup"
        )

        #expect(throws: PatientError.cannotAdmitDischarged) {
            try patient.admit(actorId: Self.actorId)
        }
    }

    // MARK: - Withdraw Happy Path

    @Test("Deve retirar paciente waitlisted da fila")
    func withdrawWaitlistedPatient() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        try patient.withdraw(
            reason: .patientDeclined,
            notes: nil,
            actorId: Self.actorId
        )

        #expect(patient.status == .discharged)
        #expect(patient.withdrawInfo != nil)
        #expect(patient.withdrawInfo?.reason == .patientDeclined)
        #expect(patient.withdrawInfo?.withdrawnBy == Self.actorId)
    }

    @Test("Deve registrar PatientWithdrawnFromWaitlistEvent")
    func withdrawRecordsEvent() throws {
        var patient = try PatientFixture.createMinimal()
        patient.clearEvents()

        try patient.withdraw(
            reason: .noResponse,
            notes: "Tentativas de contato sem sucesso",
            actorId: Self.actorId
        )

        let events = patient.uncommittedEvents
        let withdrawEvent = events.compactMap { $0 as? PatientWithdrawnFromWaitlistEvent }.first
        #expect(withdrawEvent != nil)
        #expect(withdrawEvent?.patientId == patient.id.description)
        #expect(withdrawEvent?.personId == patient.personId.description)
        #expect(withdrawEvent?.actorId == Self.actorId)
        #expect(withdrawEvent?.reason == "noResponse")
        #expect(withdrawEvent?.notes == "Tentativas de contato sem sucesso")
    }

    // MARK: - Withdraw Error Cases

    @Test("Deve falhar ao retirar paciente ja ativo")
    func withdrawActiveThrows() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")

        #expect(throws: PatientError.alreadyActive) {
            try patient.withdraw(
                reason: .patientDeclined,
                notes: nil,
                actorId: Self.actorId
            )
        }

        #expect(patient.status == .active)
    }

    @Test("Deve falhar ao retirar paciente ja desligado")
    func withdrawDischargedThrows() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: "setup"
        )

        #expect(throws: PatientError.alreadyDischarged) {
            try patient.withdraw(
                reason: .noResponse,
                notes: nil,
                actorId: Self.actorId
            )
        }
    }

    @Test("Deve falhar ao retirar com reason=other sem notes")
    func withdrawOtherReasonWithoutNotesThrows() throws {
        var patient = try PatientFixture.createMinimal()

        #expect(throws: WithdrawInfoError.notesRequiredWhenReasonIsOther) {
            try patient.withdraw(
                reason: .other,
                notes: nil,
                actorId: Self.actorId
            )
        }

        #expect(patient.status == .waitlisted)
    }

    // MARK: - Cross-transition Guards

    @Test("Deve falhar ao desligar paciente waitlisted")
    func dischargeWaitlistedThrows() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        #expect(throws: PatientError.cannotDischargeWaitlisted) {
            try patient.discharge(
                reason: .caseObjectiveAchieved,
                notes: nil,
                actorId: Self.actorId
            )
        }

        #expect(patient.status == .waitlisted)
    }

    @Test("Deve falhar ao readmitir paciente waitlisted")
    func readmitWaitlistedThrows() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        #expect(throws: PatientError.cannotReadmitWaitlisted) {
            try patient.readmit(notes: nil, actorId: Self.actorId)
        }

        #expect(patient.status == .waitlisted)
    }

    @Test("Deve bloquear mutacoes em paciente waitlisted")
    func requireActiveBlocksWaitlisted() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        #expect(throws: PatientError.patientIsWaitlisted) {
            try patient.updateHousingCondition(nil, actorId: Self.actorId)
        }
    }

    // MARK: - Full Lifecycle

    @Test("Ciclo completo: waitlisted -> active -> discharged -> readmit -> active")
    func fullWaitlistLifecycle() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .waitlisted)

        // Step 1: Admit from waitlist
        try patient.admit(actorId: "social-worker-1")
        #expect(patient.status == .active)

        // Step 2: Discharge active patient
        try patient.discharge(
            reason: .relocation,
            notes: "Mudou de cidade",
            actorId: "social-worker-1"
        )
        #expect(patient.status == .discharged)
        #expect(patient.dischargeInfo?.reason == .relocation)

        // Step 3: Readmit discharged patient
        try patient.readmit(
            notes: "Retornou ao municipio",
            actorId: "social-worker-2"
        )
        #expect(patient.status == .active)
        #expect(patient.dischargeInfo == nil)
    }
}
