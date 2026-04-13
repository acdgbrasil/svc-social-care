import Testing
import Foundation
@testable import social_care_s

@Suite("Patient Aggregate — Discharge & Readmit Lifecycle")
struct PatientDischargeTests {

    private static let actorId = "test-actor"

    // MARK: - Discharge Happy Path

    @Test("Deve desligar paciente ativo com sucesso")
    func dischargeActivePatient() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .active)

        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: Self.actorId
        )

        #expect(patient.status == .discharged)
        #expect(patient.dischargeInfo != nil)
        #expect(patient.dischargeInfo?.reason == .caseObjectiveAchieved)
        #expect(patient.dischargeInfo?.dischargedBy == Self.actorId)
    }

    @Test("Deve registrar evento PatientDischargedEvent ao desligar")
    func dischargeRecordsEvent() throws {
        var patient = try PatientFixture.createMinimal()
        let versionBefore = patient.version
        patient.clearEvents()

        try patient.discharge(
            reason: .transferredToAnotherService,
            notes: "Transferido para CRAS",
            actorId: Self.actorId
        )

        let events = patient.uncommittedEvents
        let dischargeEvent = events.compactMap { $0 as? PatientDischargedEvent }.first
        #expect(dischargeEvent != nil)
        #expect(dischargeEvent?.patientId == patient.id.description)
        #expect(dischargeEvent?.reason == "transferredToAnotherService")
        #expect(dischargeEvent?.notes == "Transferido para CRAS")
        #expect(patient.version > versionBefore)
    }

    @Test("Deve desligar com reason=other e notes validas")
    func dischargeWithOtherReasonAndNotes() throws {
        var patient = try PatientFixture.createMinimal()

        try patient.discharge(
            reason: .other,
            notes: "Situacao especifica nao coberta pelas categorias padrao",
            actorId: Self.actorId
        )

        #expect(patient.status == .discharged)
        #expect(patient.dischargeInfo?.reason == .other)
        #expect(patient.dischargeInfo?.notes != nil)
    }

    // MARK: - Discharge Error Cases

    @Test("Deve falhar ao desligar paciente ja desligado")
    func dischargeAlreadyDischarged() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: Self.actorId
        )

        #expect(throws: PatientError.alreadyDischarged) {
            try patient.discharge(
                reason: .lossOfContact,
                notes: nil,
                actorId: Self.actorId
            )
        }
    }

    @Test("Deve falhar ao desligar com reason=other sem notes")
    func dischargeOtherReasonWithoutNotes() throws {
        var patient = try PatientFixture.createMinimal()

        #expect(throws: DischargeInfoError.notesRequiredWhenReasonIsOther) {
            try patient.discharge(
                reason: .other,
                notes: nil,
                actorId: Self.actorId
            )
        }

        #expect(patient.status == .active)
    }

    @Test("Deve falhar ao desligar com notes excedendo 1000 caracteres")
    func dischargeNotesExceedMaxLength() throws {
        var patient = try PatientFixture.createMinimal()
        let longNotes = String(repeating: "x", count: 1001)

        #expect(throws: DischargeInfoError.notesExceedMaxLength(1001)) {
            try patient.discharge(
                reason: .relocation,
                notes: longNotes,
                actorId: Self.actorId
            )
        }

        #expect(patient.status == .active)
    }

    // MARK: - Readmit Happy Path

    @Test("Deve readmitir paciente desligado com sucesso")
    func readmitDischargedPatient() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.discharge(
            reason: .patientRequestedDischarge,
            notes: nil,
            actorId: Self.actorId
        )
        #expect(patient.status == .discharged)

        try patient.readmit(notes: nil, actorId: Self.actorId)

        #expect(patient.status == .active)
        #expect(patient.dischargeInfo == nil)
    }

    @Test("Deve registrar evento PatientReadmittedEvent ao readmitir")
    func readmitRecordsEvent() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.discharge(
            reason: .lossOfContact,
            notes: nil,
            actorId: Self.actorId
        )
        patient.clearEvents()

        try patient.readmit(notes: "Paciente retomou contato", actorId: Self.actorId)

        let events = patient.uncommittedEvents
        let readmitEvent = events.compactMap { $0 as? PatientReadmittedEvent }.first
        #expect(readmitEvent != nil)
        #expect(readmitEvent?.patientId == patient.id.description)
        #expect(readmitEvent?.notes == "Paciente retomou contato")
    }

    // MARK: - Readmit Error Cases

    @Test("Deve falhar ao readmitir paciente ja ativo")
    func readmitAlreadyActive() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .active)

        #expect(throws: PatientError.alreadyActive) {
            try patient.readmit(notes: nil, actorId: Self.actorId)
        }
    }

    @Test("Deve falhar ao readmitir com notes excedendo 1000 caracteres")
    func readmitNotesExceedMaxLength() throws {
        var patient = try PatientFixture.createMinimal()
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: Self.actorId
        )
        let longNotes = String(repeating: "y", count: 1001)

        #expect(throws: DischargeInfoError.notesExceedMaxLength(1001)) {
            try patient.readmit(notes: longNotes, actorId: Self.actorId)
        }

        #expect(patient.status == .discharged)
    }

    // MARK: - Full Lifecycle

    @Test("Deve completar ciclo completo: ativo -> desligado -> readmitido")
    func fullDischargeReadmitCycle() throws {
        var patient = try PatientFixture.createMinimal()
        #expect(patient.status == .active)

        // Discharge
        try patient.discharge(
            reason: .relocation,
            notes: "Mudou de cidade",
            actorId: "social-worker-1"
        )
        #expect(patient.status == .discharged)
        #expect(patient.dischargeInfo?.reason == .relocation)

        // Readmit
        try patient.readmit(
            notes: "Retornou ao municipio",
            actorId: "social-worker-2"
        )
        #expect(patient.status == .active)
        #expect(patient.dischargeInfo == nil)

        // Discharge again
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: "social-worker-1"
        )
        #expect(patient.status == .discharged)
        #expect(patient.dischargeInfo?.reason == .caseObjectiveAchieved)
    }

    @Test("Deve preservar dados do paciente apos desligamento")
    func dischargePreservesPatientData() throws {
        var patient = try PatientFixture.createMinimal()
        let originalPersonId = patient.personId
        let originalDiagnoses = patient.diagnoses
        let originalFamilyMembers = patient.familyMembers

        try patient.discharge(
            reason: .death,
            notes: nil,
            actorId: Self.actorId
        )

        #expect(patient.personId == originalPersonId)
        #expect(patient.diagnoses.count == originalDiagnoses.count)
        #expect(patient.familyMembers.count == originalFamilyMembers.count)
    }
}
