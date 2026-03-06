import Testing
import Foundation
@testable import social_care_s

@Suite("GetPatientByPersonIdService Specification")
struct GetPatientByPersonIdServiceTests {

    class MockRepo: PatientRepository, @unchecked Sendable {
        var mockedPatient: Patient?
        var calledPersonId: PersonId?
        
        func save(_ patient: Patient) async throws {}
        func exists(byPersonId personId: PersonId) async throws -> Bool { return false }
        
        func find(byPersonId personId: PersonId) async throws -> Patient? {
            calledPersonId = personId
            return mockedPatient
        }
        
        func find(byId id: UUID) async throws -> Patient? { return nil }
    }

    @Test("Deve retornar erro se não houver paciente atrelado a este PersonId")
    func testNotFound() async throws {
        let repo = MockRepo()
        repo.mockedPatient = nil
        
        let service = GetPatientByPersonIdService(repository: repo)
        let personId = PersonId()
        let query = GetPatientByPersonIdQuery(personId: personId.description)
        
        await #expect(throws: GetPatientByPersonIdError.patientNotFound) {
            try await service.execute(query)
        }
    }
    
    @Test("Deve retornar o DTO se o paciente existir para o PersonId")
    func testFound() async throws {
        let repo = MockRepo()
        
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        
        let mockPatient = try Patient(
            id: PatientId(), 
            personId: pId, 
            diagnoses: [diag], 
            familyMembers: [prMember], 
            prRelationshipId: prId
        )
        
        repo.mockedPatient = mockPatient
        
        let service = GetPatientByPersonIdService(repository: repo)
        let query = GetPatientByPersonIdQuery(personId: pId.description)
        
        let resultDTO = try await service.execute(query)
        
        #expect(repo.calledPersonId?.description == pId.description)
        #expect(resultDTO.patientId == mockPatient.id.description)
        #expect(resultDTO.personId == pId.description)
    }
}
