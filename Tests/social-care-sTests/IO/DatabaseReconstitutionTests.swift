import Testing
@testable import social_care_s
import Foundation

@Suite("Database Reconstitution Specification")
struct DatabaseReconstitutionTests {

    @Test("Deve reconstituir Agregado Patient completo do banco")
    func fullReconstitution() throws {
        // 1. Setup Mock Models (Simulando dados vindos do banco)
        let patientUUID = UUID()
        let personUUID = UUID()
        
        let patientModel = PatientModel(
            id: patientUUID,
            person_id: personUUID,
            version: 1,
            personal_data: nil,
            civil_documents: nil,
            address: nil,
            housing_condition: nil,
            socioeconomic_situation: nil,
            community_support_network: nil,
            social_health_summary: nil,
            social_identity: nil,
            work_and_income: nil,
            educational_status: nil,
            health_status: nil,
            placement_history: nil,
            intake_info: nil
        )
        
        let familyModel = FamilyMemberModel(
            patient_id: patientUUID,
            person_id: UUID(),
            relationship: UUID().uuidString,
            is_primary_caregiver: true,
            resides_with_patient: true,
            has_disability: false,
            required_documents: "[]".data(using: .utf8)!,
            birth_date: Date()
        )
        
        // 2. Map Back to Domain
        let patient = try PatientDatabaseMapper.toDomain(
            patient: patientModel,
            diagnoses: [],
            familyMembers: [familyModel],
            appointments: [],
            referrals: [],
            reports: []
        )
        
        #expect(patient.id.description == patientUUID.uuidString.lowercased())
        #expect(patient.familyMembers.count == 1)
    }
}
