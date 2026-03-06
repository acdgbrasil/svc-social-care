import Testing
import Foundation
@testable import social_care_s

@Suite("GetPatientByIdService Specification")
struct GetPatientByIdServiceTests {

    class MockRepo: PatientRepository, @unchecked Sendable {
        var mockedPatient: Patient?
        var calledId: UUID?
        
        func save(_ patient: Patient) async throws {}
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        func find(byPersonId personId: PersonId) async throws -> Patient? { return nil }
        
        func find(byId id: UUID) async throws -> Patient? {
            calledId = id
            return mockedPatient
        }
    }

    @Test("Deve retornar erro NotFound se o paciente não existir")
    func testNotFound() async throws {
        let repo = MockRepo()
        repo.mockedPatient = nil
        
        let service = GetPatientByIdService(repository: repo)
        let query = GetPatientByIdQuery(patientId: UUID())
        
        await #expect(throws: GetPatientByIdError.patientNotFound) {
            try await service.execute(query)
        }
    }
    
    @Test("Deve retornar o DTO correto se o paciente existir")
    func testFound() async throws {
        let repo = MockRepo()
        
        // Mock Patient
        let pId = PersonId()
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prId = try LookupId(UUID().uuidString)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        let mockPatient = try Patient(id: PatientId(), personId: pId, diagnoses: [diag], familyMembers: [prMember], prRelationshipId: prId)
        
        repo.mockedPatient = mockPatient
        
        let service = GetPatientByIdService(repository: repo)
        let targetId = UUID(uuidString: mockPatient.id.description)!
        let query = GetPatientByIdQuery(patientId: targetId)
        
        let resultDTO = try await service.execute(query)
        
        #expect(repo.calledId == targetId)
        #expect(resultDTO.patientId == targetId.uuidString.lowercased())
        #expect(resultDTO.personId == mockPatient.personId.description)
        #expect(resultDTO.familyMembers.count == 1)
        #expect(resultDTO.diagnoses.count == 1)
    }
}
