import Foundation
import SQLKit

struct AddWaitlistSupport: Migration {
    let name = "2026_04_12_AddWaitlistSupport"

    func prepare(on db: any SQLDatabase) async throws {
        // Change DEFAULT for status from 'active' to 'waitlisted'
        try await db.raw("ALTER TABLE patients ALTER COLUMN status SET DEFAULT 'waitlisted'").run()

        // Add withdraw info columns
        try await db.raw("""
            ALTER TABLE patients
            ADD COLUMN withdraw_reason VARCHAR(50),
            ADD COLUMN withdraw_notes TEXT,
            ADD COLUMN withdrawn_at TIMESTAMPTZ,
            ADD COLUMN withdrawn_by VARCHAR(255)
        """).run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.raw("ALTER TABLE patients ALTER COLUMN status SET DEFAULT 'active'").run()
        try await db.raw("""
            ALTER TABLE patients
            DROP COLUMN IF EXISTS withdraw_reason,
            DROP COLUMN IF EXISTS withdraw_notes,
            DROP COLUMN IF EXISTS withdrawn_at,
            DROP COLUMN IF EXISTS withdrawn_by
        """).run()
    }
}
