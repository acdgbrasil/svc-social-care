import Foundation
import SQLKit

/// Modelo de banco de dados para a tabela 'patients'.
struct PatientModel: Codable {
    let id: UUID
    let person_id: UUID
    let version: Int
    
    // Campos complexos persistidos como JSON para manter a coesão do Agregado no SQLKit
    let housing_condition: Data?
    let socioeconomic_situation: Data?
    let community_support_network: Data?
    let social_health_summary: Data?
    
    enum CodingKeys: String, CodingKey {
        case id
        case person_id = "person_id"
        case version
        case housing_condition = "housing_condition"
        case socioeconomic_situation = "socioeconomic_situation"
        case community_support_network = "community_support_network"
        case social_health_summary = "social_health_summary"
    }
}

/// Modelo para a tabela 'family_members'.
struct FamilyMemberModel: Codable {
    let patient_id: UUID
    let person_id: UUID
    let relationship: String
    let is_primary_caregiver: Bool
    let resides_with_patient: Bool
}

/// Modelo para a tabela 'patient_diagnoses'.
struct DiagnosisModel: Codable {
    let patient_id: UUID
    let icd_code: String
    let date: Date
    let description: String
}

/// Modelo para a tabela 'social_care_appointments'.
struct AppointmentModel: Codable {
    let id: UUID
    let patient_id: UUID
    let date: Date
    let professional_in_charge_id: UUID
    let type: String
    let summary: String
    let action_plan: String
}

/// Modelo para a tabela 'referrals'.
struct ReferralModel: Codable {
    let id: UUID
    let patient_id: UUID
    let date: Date
    let requesting_professional_id: UUID
    let referred_person_id: UUID
    let destination_service: String
    let reason: String
    let status: String
}

/// Modelo para a tabela 'rights_violation_reports'.
struct ViolationReportModel: Codable {
    let id: UUID
    let patient_id: UUID
    let report_date: Date
    let incident_date: Date?
    let victim_id: UUID
    let violation_type: String
    let description_of_fact: String
    let actions_taken: String
}

/// Modelo para a tabela 'outbox_messages' (Pattern Outbox).
struct OutboxMessageModel: Codable {
    let id: UUID
    let event_type: String
    let payload: Data
    let occurred_at: Date
    let processed_at: Date?
}
