import Testing
import Foundation
@testable import social_care_s

@Suite("AssignPrimaryCaregiver Command Handler")
struct AssignPrimaryCaregiverTests {

    @Test("Deve atribuir cuidador principal com sucesso")
    func successfulAssignment() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try PatientFixture.createWithAdditionalMember()
        await repo.seed(patient)

        let handler = AssignPrimaryCaregiverCommandHandler(repository: repo, eventBus: bus)

        try await handler.handle(AssignPrimaryCaregiverCommand(
            patientId: PatientFixture.defaultPersonId,
            memberPersonId: PatientFixture.defaultMemberId,
            actorId: "actor-1"
        ))

        let saved = try await repo.find(byPersonId: PersonId(PatientFixture.defaultPersonId))
        let newCaregiver = saved?.familyMembers.first { $0.personId.description == PatientFixture.defaultMemberId }
        #expect(newCaregiver?.isPrimaryCaregiver == true)

        let eventCount = await bus.eventCount()
        #expect(eventCount >= 1)
    }

    @Test("Deve falhar quando membro nao pertence a familia")
    func memberNotInFamily() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let patient = try PatientFixture.createMinimal()
        await repo.seed(patient)

        let handler = AssignPrimaryCaregiverCommandHandler(repository: repo, eventBus: bus)

        await #expect(throws: AssignPrimaryCaregiverError.self) {
            try await handler.handle(AssignPrimaryCaregiverCommand(
                patientId: PatientFixture.defaultPersonId,
                memberPersonId: UUID().uuidString,
                actorId: "actor-1"
            ))
        }
    }

    @Test("Deve falhar quando paciente nao encontrado")
    func patientNotFound() async throws {
        let repo = InMemoryPatientRepository()
        let bus = InMemoryEventBus()
        let handler = AssignPrimaryCaregiverCommandHandler(repository: repo, eventBus: bus)

        await #expect(throws: AssignPrimaryCaregiverError.self) {
            try await handler.handle(AssignPrimaryCaregiverCommand(
                patientId: UUID().uuidString,
                memberPersonId: UUID().uuidString,
                actorId: "actor-1"
            ))
        }
    }
}
