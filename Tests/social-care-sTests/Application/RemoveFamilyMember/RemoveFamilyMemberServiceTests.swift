import Testing
import Foundation
@testable import social_care_s

@Suite("RemoveFamilyMemberService Specification")
struct RemoveFamilyMemberServiceTests {

    class MockRepo: PatientRepository, @unchecked Sendable {
        var savedPatient: Patient?
        var mockedPatient: Patient?
        
        func save(_ patient: Patient) async throws { savedPatient = patient }
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        func find(byPersonId personId: PersonId) async throws -> Patient? { return nil }
        func find(byId id: UUID) async throws -> Patient? { return mockedPatient }
    }

    class MockBus: EventBus, @unchecked Sendable {
        var events: [any DomainEvent] = []
        func publish(_ events: [any DomainEvent]) async throws { self.events.append(contentsOf: events) }
    }

    @Test("Deve remover membro com sucesso")
    func testRemoveSuccess() async throws {
        let repo = MockRepo()
        let bus = MockBus()
        let sut = RemoveFamilyMemberService(repository: repo, eventBus: bus)
        
        // Setup: Paciente com 2 membros (PR + outro)
        let pId = PersonId()
        let memberIdToRemove = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        let otherMember = try FamilyMember(personId: memberIdToRemove, relationshipId: try LookupId(UUID().uuidString), isPrimaryCaregiver: false, residesWithPatient: true, birthDate: .now)
        
        repo.mockedPatient = try Patient(id: PatientId(), personId: pId, diagnoses: [diag], familyMembers: [prMember, otherMember], prRelationshipId: prId)
        
        let command = RemoveFamilyMemberCommand(patientId: repo.mockedPatient!.id.description, memberId: memberIdToRemove.description)
        try await sut.execute(command: command)
        
        #expect(repo.savedPatient?.familyMembers.count == 1)
        #expect(bus.events.contains { $0 is FamilyMemberRemovedEvent })
    }

    @Test("Deve falhar se o membro não pertencer à família")
    func testMemberNotFound() async throws {
        let repo = MockRepo()
        let sut = RemoveFamilyMemberService(repository: repo, eventBus: MockBus())
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        repo.mockedPatient = try Patient(id: PatientId(), personId: pId, diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)], familyMembers: [try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)], prRelationshipId: prId)
        
        let missingId = UUID().uuidString.lowercased()
        let command = RemoveFamilyMemberCommand(patientId: repo.mockedPatient!.id.description, memberId: missingId)
        
        await #expect(throws: RemoveFamilyMemberError.familyMemberNotFound(personId: missingId)) {
            try await sut.execute(command: command)
        }
    }
}
