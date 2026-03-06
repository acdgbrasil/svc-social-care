import Foundation
import SQLKit

struct AddPerformanceIndexes: Migration {
    let name = "2026_03_07_AddPerformanceIndexes"

    func prepare(on db: any SQLDatabase) async throws {
        // 1. Índice e Constraint Unique para PersonId em Patients
        // Garante que uma pessoa só tenha UM prontuário social
        try await db.create(index: "idx_patients_person_id")
            .on("patients")
            .column("person_id")
            .unique()
            .run()

        // 2. Índice Parcial para o Outbox Relay (Missão Crítica)
        // Filtra apenas o que não foi processado, otimizando o polling
        try await db.execute(sql: SQLRaw("""
            CREATE INDEX idx_outbox_unprocessed 
            ON outbox_messages (occurred_at ASC) 
            WHERE processed_at IS NULL
        """), { _ in }).get()

        // 3. Índice para busca de membros da família
        try await db.create(index: "idx_family_members_person_id")
            .on("family_members")
            .column("person_id")
            .run()
            
        // 4. Índice para busca de diagnósticos por código (Analytics)
        try await db.create(index: "idx_diagnoses_code")
            .on("patient_diagnoses")
            .column("icd_code")
            .run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.drop(index: "idx_diagnoses_code").run()
        try await db.drop(index: "idx_family_members_person_id").run()
        try await db.drop(index: "idx_outbox_unprocessed").run()
        try await db.drop(index: "idx_patients_person_id").run()
    }
}
