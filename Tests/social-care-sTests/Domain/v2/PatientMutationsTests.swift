import Testing
@testable import social_care_s
import Foundation

@Suite("Patient Aggregate Mutation & Analytics Specification")
struct PatientMutationsTests {

    @Test("Deve atualizar módulos de avaliação e incrementar versão")
    func moduleUpdates() throws {
        var patient = try createMinimalPatient()
        let initialVersion = patient.version
        
        try patient.updateHousingCondition(nil, actorId: "test-actor")
        #expect(patient.version == initialVersion + 1)
        
        try patient.updateWorkAndIncome(nil, actorId: "test-actor")
        #expect(patient.version == initialVersion + 2)
        
        try patient.updateEducationalStatus(nil, actorId: "test-actor")
        #expect(patient.version == initialVersion + 3)
    }

    @Test("Deve identificar membros na fronteira (containsPerson)")
    func boundaryCheck() throws {
        let pId = PersonId()
        let familyId = PersonId()
        let prId = try LookupId(UUID().uuidString)

        let prMember = FamilyMember(personId: familyId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)

        let patient = try Patient(
            id: PatientId(),
            personId: pId,
            diagnoses: [try createDiagnosis()],
            familyMembers: [prMember],
            prRelationshipId: prId,
            actorId: "test-actor"
        )

        #expect(patient.containsPerson(pId) == true)
        #expect(patient.containsPerson(familyId) == true)
        #expect(patient.containsPerson(PersonId()) == false)
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
            prRelationshipId: prId,
            actorId: "test-actor"
        )
        
        #expect(patient.countMembers(inAgeRange: 0...10, at: now) == 1)
        #expect(patient.countMembers(inAgeRange: 11...20, at: now) == 1)
    }
}

// MARK: - Helpers

private func createMinimalPatient() throws -> Patient {
    let pId = PersonId()
    let prId = try LookupId(UUID().uuidString)
    let prMember = FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
    let patient = try Patient(id: PatientId(), personId: pId, diagnoses: [try createDiagnosis()], familyMembers: [prMember], prRelationshipId: prId, actorId: "test-actor")
    return patient
}

private func createDiagnosis() throws -> Diagnosis {
    return try Diagnosis(id: try ICDCode("B201"), date: .now, description: "Test", now: .now)
}

private func createMember(birth: String, rid: LookupId) throws -> FamilyMember {
    return FamilyMember(
        personId: PersonId(),
        relationshipId: rid,
        isPrimaryCaregiver: false,
        residesWithPatient: true,
        birthDate: try TimeStamp(iso: birth)
    )
}
