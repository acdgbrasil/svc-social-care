import Testing
import Foundation
@testable import social_care_s

@Suite("WithdrawFromWaitlist Command Handler")
struct WithdrawFromWaitlistTests {

    private static let actorId = "actor-social-worker"

    private static func makeCommand(
        patientId: String = "placeholder",
        reason: String = "patientDeclined",
        notes: String? = nil,
        actorId: String = WithdrawFromWaitlistTests.actorId
    ) -> WithdrawFromWaitlistCommand {
        WithdrawFromWaitlistCommand(
            patientId: patientId,
            reason: reason,
            notes: notes,
            actorId: actorId
        )
    }

    /// Creates a waitlisted patient (default from createMinimal), clears events, seeds in repo.
    private static func seedWaitlistedPatient(
        repo: InMemoryPatientRepository
    ) async throws -> Patient {
        var patient = try PatientFixture.createMinimal()
        patient.clearEvents()
        await repo.seed(patient)
        return patient
    }

    /// Creates an active patient (waitlisted + admit), clears events, seeds in repo.
    private static func seedActivePatient(
        repo: InMemoryPatientRepository
    ) async throws -> Patient {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")
        patient.clearEvents()
        await repo.seed(patient)
        return patient
    }

    /// Creates a discharged patient (waitlisted + admit + discharge), clears events, seeds in repo.
    private static func seedDischargedPatient(
        repo: InMemoryPatientRepository
    ) async throws -> Patient {
        var patient = try PatientFixture.createMinimal()
        try patient.admit(actorId: "setup")
        try patient.discharge(
            reason: .caseObjectiveAchieved,
            notes: nil,
            actorId: "setup"
        )
        patient.clearEvents()
        await repo.seed(patient)
        return patient
    }

    // MARK: - Happy Path

    @Test("Deve retirar paciente waitlisted da fila com sucesso")
    func successfulWithdraw() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        try await handler.handle(Self.makeCommand(
            patientId: patient.id.description,
            reason: "patientDeclined"
        ))

        let saved = await repo.stored(byId: patient.id)
        #expect(saved?.status == .discharged)
        #expect(saved?.withdrawInfo != nil)
        #expect(saved?.withdrawInfo?.reason == .patientDeclined)

        let saveCount = await repo.saveCallCount
        #expect(saveCount == 1)
    }

    @Test("Deve retirar com reason=other e notes validas")
    func successfulWithdrawWithOtherReason() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        try await handler.handle(Self.makeCommand(
            patientId: patient.id.description,
            reason: "other",
            notes: "Motivo especifico nao categorizado"
        ))

        let saved = await repo.stored(byId: patient.id)
        #expect(saved?.status == .discharged)
        #expect(saved?.withdrawInfo?.reason == .other)
        #expect(saved?.withdrawInfo?.notes == "Motivo especifico nao categorizado")
    }

    @Test("Deve publicar evento apos persistencia")
    func eventPublishedAfterPersistence() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        try await handler.handle(Self.makeCommand(
            patientId: patient.id.description,
            reason: "noResponse"
        ))

        let lastEvent = await bus.lastEvent()
        #expect(lastEvent is PatientWithdrawnFromWaitlistEvent)
    }

    // MARK: - Error Cases

    @Test("Deve falhar quando paciente nao encontrado")
    func patientNotFound() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        let nonExistentId = PatientId().description

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: nonExistentId
            ))
        }

        let eventCount = await bus.eventCount()
        #expect(eventCount == 0)
    }

    @Test("Deve falhar quando paciente ja esta desligado")
    func alreadyDischarged() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedDischargedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: patient.id.description
            ))
        }
    }

    @Test("Deve falhar quando paciente esta ativo")
    func patientIsActive() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedActivePatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: patient.id.description
            ))
        }
    }

    @Test("Deve falhar com razao invalida")
    func invalidReason() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: patient.id.description,
                reason: "invalidReasonThatDoesNotExist"
            ))
        }
    }

    @Test("Deve falhar com reason=other sem notes")
    func otherReasonWithoutNotes() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: patient.id.description,
                reason: "other",
                notes: nil
            ))
        }

        let saved = await repo.stored(byId: patient.id)
        #expect(saved?.status == .waitlisted)
    }

    @Test("Deve falhar quando notes excede 1000 caracteres")
    func notesExceedMaxLength() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try await Self.seedWaitlistedPatient(repo: repo)

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        let longNotes = String(repeating: "z", count: 1001)

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: patient.id.description,
                reason: "patientDeclined",
                notes: longNotes
            ))
        }
    }

    @Test("Deve falhar com formato de patientId invalido")
    func invalidPatientIdFormat() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()

        let handler = WithdrawFromWaitlistCommandHandler(
            repository: repo, eventBus: bus
        )

        await #expect(throws: WithdrawFromWaitlistError.self) {
            try await handler.handle(Self.makeCommand(
                patientId: "not-a-valid-uuid"
            ))
        }
    }
}
