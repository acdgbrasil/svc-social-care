import Testing
@testable import social_care_s
import Foundation

@Suite("Database Mapper Specification")
struct DatabaseMapperTests {

    @Test("Deve converter Agregado Patient para Modelos de Banco")
    func patientToDatabase() throws {
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        
        let patient = try Patient(id: PatientId(), personId: pId, diagnoses: [diag], familyMembers: [prMember], prRelationshipId: prId)
        
        let dbModels = try PatientDatabaseMapper.toDatabase(patient)
        
        #expect(dbModels.patient.person_id == UUID(uuidString: pId.description))
        #expect(dbModels.diagnoses.count == 1)
        #expect(dbModels.familyMembers.count == 1)
    }

    @Test("Deve garantir integridade dos campos v2.0 no mapeamento (Round-trip)")
    func v2FieldsRoundTrip() throws {
        // 1. Setup com campos v2.0
        let pId = PersonId()
        let prId = try LookupId(UUID().uuidString)
        let diag = try Diagnosis(id: try ICDCode("B201"), date: .now, description: "D", now: .now)
        let prMember = try FamilyMember(personId: pId, relationshipId: prId, isPrimaryCaregiver: true, residesWithPatient: true, birthDate: .now)
        
        var patient = try Patient(
            id: PatientId(), 
            personId: pId, 
            diagnoses: [diag], 
            familyMembers: [prMember], 
            prRelationshipId: prId
        )
        
        // Mock de WorkAndIncome
        let incomeVO = WorkIncomeVO(
            memberId: pId, 
            occupationId: try LookupId(UUID().uuidString), 
            hasWorkCard: true, 
            monthlyAmount: 1500.0
        )
        let work = WorkAndIncome(
            familyId: patient.id,
            individualIncomes: [incomeVO],
            socialBenefits: [],
            hasRetiredMembers: false
        )
        patient.updateWorkAndIncome(work)
        
        // 2. Map to Database
        let dbModels = try PatientDatabaseMapper.toDatabase(patient)
        
        // 3. Map back to Domain
        let reconstituted = try PatientDatabaseMapper.toDomain(
            patient: dbModels.patient,
            diagnoses: dbModels.diagnoses,
            familyMembers: dbModels.familyMembers,
            appointments: dbModels.appointments,
            referrals: dbModels.referrals,
            reports: dbModels.reports
        )
        
        // 4. Verify
        #expect(reconstituted.workAndIncome?.individualIncomes.first?.monthlyAmount == 1500.0)
    }

    @Test("Deve converter eventos de domínio para Outbox")
    func outboxMapping() throws {
        let event = PatientCreatedEvent(patientId: "123", personId: "456", occurredAt: Date())
        let messages = try PatientDatabaseMapper.toOutbox([event])
        
        #expect(messages.count == 1)
        #expect(messages.first?.event_type == "PatientCreatedEvent")
    }
}
