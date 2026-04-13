import Foundation
import SQLKit

struct AddPatientDischarge: Migration {
    let name = "2026_04_12_AddPatientDischarge"

    func prepare(on db: any SQLDatabase) async throws {
        try await db.raw("""
            ALTER TABLE patients
            ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active',
            ADD COLUMN discharge_reason VARCHAR(50),
            ADD COLUMN discharge_notes TEXT,
            ADD COLUMN discharged_at TIMESTAMPTZ,
            ADD COLUMN discharged_by VARCHAR(255)
        """).run()

        try await db.raw("""
            CREATE INDEX idx_patients_status ON patients(status)
        """).run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.raw("DROP INDEX IF EXISTS idx_patients_status").run()
        try await db.raw("""
            ALTER TABLE patients
            DROP COLUMN IF EXISTS status,
            DROP COLUMN IF EXISTS discharge_reason,
            DROP COLUMN IF EXISTS discharge_notes,
            DROP COLUMN IF EXISTS discharged_at,
            DROP COLUMN IF EXISTS discharged_by
        """).run()
    }
}
