import Testing
import Foundation
@testable import social_care_s

@Suite("UpdatePlacementHistoryService Specification")
struct UpdatePlacementHistoryServiceTests {

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

    @Test("Deve atualizar histórico de acolhimento com sucesso")
    func testUpdateSuccess() async throws {
        let repo = MockRepo()
        let bus = MockBus()
        let sut = UpdatePlacementHistoryService(repository: repo, eventBus: bus)
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        
        repo.mockedPatient = try Patient(
            id: PatientId(), personId: pId, 
            diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)], 
            familyMembers: [prMember], 
            prRelationshipId: prId
        )
        
        let command = UpdatePlacementHistoryCommand(
            patientId: repo.mockedPatient!.id.description, 
            registries: [
                .init(memberId: pId.description, startDate: Date(), endDate: nil, reason: "Neglect")
            ], 
            collectiveSituations: .init(homeLossReport: "Flood", thirdPartyGuardReport: nil), 
            separationChecklist: .init(adultInPrison: false, adolescentInInternment: false)
        )
        
        try await sut.execute(command: command)
        
        #expect(repo.savedPatient?.placementHistory != nil)
        #expect(repo.savedPatient?.placementHistory?.collectiveSituations.homeLossReport == "Flood")
    }

    @Test("Deve falhar se o membro informado no acolhimento não existir na família")
    func testMemberNotFound() async throws {
        let repo = MockRepo()
        let sut = UpdatePlacementHistoryService(repository: repo, eventBus: MockBus())
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        repo.mockedPatient = try Patient(id: PatientId(), personId: pId, diagnoses: [try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)], familyMembers: [try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)], prRelationshipId: prId)
        
        let invalidMemberId = UUID().uuidString.lowercased()
        let command = UpdatePlacementHistoryCommand(
            patientId: repo.mockedPatient!.id.description, 
            registries: [
                .init(memberId: invalidMemberId, startDate: Date(), endDate: nil, reason: "X")
            ], 
            collectiveSituations: .init(homeLossReport: nil, thirdPartyGuardReport: nil), 
            separationChecklist: .init(adultInPrison: false, adolescentInInternment: false)
        )
        
        await #expect(throws: UpdatePlacementHistoryError.memberNotFound(invalidMemberId)) {
            try await sut.execute(command: command)
        }
    }
}
