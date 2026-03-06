import Testing
@testable import social_care_s
import Foundation

@Suite("AddFamilyMember Application Use Case Specification")
struct AddFamilyMemberApplicationTests {

    class MockRepo: PatientRepository, @unchecked Sendable {
        var savedPatient: Patient?
        var findResult: Patient?
        
        func save(_ patient: Patient) async throws { self.savedPatient = patient }
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        func find(byPersonId personId: PersonId) async throws -> Patient? { return findResult }
        func find(byId id: UUID) async throws -> Patient? { return nil }
    }

    struct MockBus: EventBus, Sendable {
        func publish(_ events: [any DomainEvent]) async throws {}
    }

    struct MockLookupValidator: LookupValidating {
        func exists(id: LookupId, in table: String) async throws -> Bool { true }
    }

    @Test("Deve adicionar membro familiar com sucesso")
    func addMember() async throws {
        let repo = MockRepo()
        let bus = MockBus()
        let sut = AddFamilyMemberService(patientRepository: repo, eventBus: bus, lookupValidator: MockLookupValidator())
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)]
        
        // Setup: paciente já existe com uma PR
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        repo.findResult = try Patient(id: PatientId(), personId: pId, diagnoses: diag, familyMembers: [prMember], prRelationshipId: prId)
        
        let command = AddFamilyMemberCommand(
            patientPersonId: pId.description,
            memberPersonId: PersonId().description,
            relationship: try LookupId(UUID().uuidString).description,
            isResiding: true,
            isCaregiver: false,
            hasDisability: false,
            requiredDocuments: [],
            birthDate: Date()
        )
        
        try await sut.execute(command: command)
        #expect(repo.savedPatient?.familyMembers.count == 2)
    }
}
