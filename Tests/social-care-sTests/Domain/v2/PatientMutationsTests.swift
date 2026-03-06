import Testing
@testable import social_care_s
import Foundation

@Suite("Patient Aggregate Mutation & Analytics Specification")
struct PatientMutationsTests {

    @Test("Deve atualizar módulos de avaliação e incrementar versão")
    func moduleUpdates() throws {
        var patient = try createMinimalPatient()
        let initialVersion = patient.version
        
        patient.updateHousingCondition(nil)
        #expect(patient.version == initialVersion + 1)
        
        patient.updateWorkAndIncome(nil)
        #expect(patient.version == initialVersion + 2)
        
        patient.updateEducationalStatus(nil)
        #expect(patient.version == initialVersion + 3)
    }

    @Test("Deve identificar membros na fronteira (belongsToBoundary)")
    func boundaryCheck() throws {
        let pId = PersonId()
        let familyId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        
        let prMember = try FamilyMember(personId: familyId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        
        let patient = try Patient(
            id: PatientId(), 
            personId: pId, 
            diagnoses: [try createDiagnosis()], 
            familyMembers: [prMember], 
            prRelationshipId: prId
        )
        
        #expect(patient.belongsToBoundary(pId) == true)
        #expect(patient.belongsToBoundary(familyId) == true)
        #expect(patient.belongsToBoundary(PersonId()) == false)
    }

    @Test("Deve contar membros por faixa etária corretamente")
    func ageCounting() throws {
        let prId = try LookupId(UUID().uuidString)
        let now = try TimeStamp(iso: "2024-01-01T00:00:00Z")
        
        let m1 = try createMember(birth: "2020-01-01T00:00:00Z", rid: prId) // 4 anos
        let m2 = try createMember(birth: "2010-01-01T00:00:00Z", rid: try LookupId(UUID().uuidString)) // 14 anos
        
        let patient = try Patient(
            id: PatientId(), 
            personId: PersonId(), 
            diagnoses: [try createDiagnosis()], 
            familyMembers: [m1, m2], 
            prRelationshipId: prId
        )
        
        #expect(patient.countInAgeRange(min: 0, max: 10, now: now) == 1)
        #expect(patient.countInAgeRange(min: 11, max: 20, now: now) == 1)
    }
}

// MARK: - Helpers

private func createMinimalPatient() throws -> Patient {
    let pId = PersonId()
    let prId = try LookupId(UUID().uuidString)
    let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
    return try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId)
}

private func createDiagnosis() throws -> Diagnosis {
    return try Diagnosis(id: try ICDCode("B201"), date: .now, description: "Test", now: .now)
}

private func createMember(birth: String, rid: LookupId) throws -> FamilyMember {
    return try FamilyMember(
        personId: PersonId(), 
        relationshipId: rid, 
        isPrimaryCaregiver: false, 
        residesWithPatient: true, 
        birthDate: try TimeStamp(iso: birth)
    )
}
