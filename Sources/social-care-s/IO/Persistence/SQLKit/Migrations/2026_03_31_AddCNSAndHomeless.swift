import SQLKit

struct AddCNSAndHomeless: Migration {
    let name = "2026_03_31_AddCNSAndHomeless"

    func prepare(on db: any SQLDatabase) async throws {
        // CNS columns on patients table
        try await db.alter(table: "patients")
            .column("cns_number", type: .text)
            .run()
        try await db.alter(table: "patients")
            .column("cns_cpf", type: .text)
            .run()
        try await db.alter(table: "patients")
            .column("cns_qr_code", type: .text)
            .run()

        // isHomeless column on patients table
        try await db.alter(table: "patients")
            .column("address_is_homeless", type: .custom(SQLRaw("BOOLEAN")))
            .run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.raw("ALTER TABLE patients DROP COLUMN IF EXISTS cns_number").run()
        try await db.raw("ALTER TABLE patients DROP COLUMN IF EXISTS cns_cpf").run()
        try await db.raw("ALTER TABLE patients DROP COLUMN IF EXISTS cns_qr_code").run()
        try await db.raw("ALTER TABLE patients DROP COLUMN IF EXISTS address_is_homeless").run()
    }
}
