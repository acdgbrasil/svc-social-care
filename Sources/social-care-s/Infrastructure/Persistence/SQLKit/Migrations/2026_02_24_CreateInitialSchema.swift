import Foundation
import SQLKit

struct CreateInitialSchema: Migration {
    let name = "2026_02_24_CreateInitialSchema"
    
    func prepare(on db: any SQLDatabase) async throws {
        // Tipos customizados para PostgreSQL
        let uuidType = SQLRaw("UUID")
        let jsonbType = SQLRaw("JSONB")
        let timestampType = SQLRaw("TIMESTAMP")
        let booleanType = SQLRaw("BOOLEAN")
        
        // 1. Tabela de Pacientes (Aggregate Root)
        try await db.create(table: "patients")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("person_id", type: .custom(uuidType), .notNull)
            .column("version", type: .int, .notNull)
            .column("housing_condition", type: .custom(jsonbType))
            .column("socioeconomic_situation", type: .custom(jsonbType))
            .column("community_support_network", type: .custom(jsonbType))
            .column("social_health_summary", type: .custom(jsonbType))
            .run()
            
        // 2. Tabela de Diagnósticos (One-to-Many)
        try await db.create(table: "patient_diagnoses")
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("icd_code", type: .text, .notNull)
            .column("date", type: .custom(timestampType), .notNull)
            .column("description", type: .text, .notNull)
            .run()
            
        // 3. Tabela de Membros da Família
        try await db.create(table: "family_members")
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("person_id", type: .custom(uuidType), .notNull)
            .column("relationship", type: .text, .notNull)
            .column("is_primary_caregiver", type: .custom(booleanType), .notNull)
            .column("resides_with_patient", type: .custom(booleanType), .notNull)
            .run()
            
        // 4. Tabela de Atendimentos
        try await db.create(table: "social_care_appointments")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("date", type: .custom(timestampType), .notNull)
            .column("professional_in_charge_id", type: .custom(uuidType), .notNull)
            .column("type", type: .text, .notNull)
            .column("summary", type: .text, .notNull)
            .column("action_plan", type: .text, .notNull)
            .run()
            
        // 5. Tabela de Encaminhamentos
        try await db.create(table: "referrals")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("date", type: .custom(timestampType), .notNull)
            .column("requesting_professional_id", type: .custom(uuidType), .notNull)
            .column("referred_person_id", type: .custom(uuidType), .notNull)
            .column("destination_service", type: .text, .notNull)
            .column("reason", type: .text, .notNull)
            .column("status", type: .text, .notNull)
            .run()
            
        // 6. Tabela de Violações de Direitos
        try await db.create(table: "rights_violation_reports")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("patient_id", type: .custom(uuidType), .notNull, .references("patients", "id", onDelete: .cascade))
            .column("report_date", type: .custom(timestampType), .notNull)
            .column("incident_date", type: .custom(timestampType))
            .column("victim_id", type: .custom(uuidType), .notNull)
            .column("violation_type", type: .text, .notNull)
            .column("description_of_fact", type: .text, .notNull)
            .column("actions_taken", type: .text, .notNull)
            .run()
            
        // 7. Tabela de Outbox (Pattern Outbox)
        try await db.create(table: "outbox_messages")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("event_type", type: .text, .notNull)
            .column("payload", type: .custom(jsonbType), .notNull)
            .column("occurred_at", type: .custom(timestampType), .notNull)
            .column("processed_at", type: .custom(timestampType))
            .run()
    }
    
    func revert(on db: any SQLDatabase) async throws {
        try await db.drop(table: "outbox_messages").run()
        try await db.drop(table: "rights_violation_reports").run()
        try await db.drop(table: "referrals").run()
        try await db.drop(table: "social_care_appointments").run()
        try await db.drop(table: "family_members").run()
        try await db.drop(table: "patient_diagnoses").run()
        try await db.drop(table: "patients").run()
    }
}
