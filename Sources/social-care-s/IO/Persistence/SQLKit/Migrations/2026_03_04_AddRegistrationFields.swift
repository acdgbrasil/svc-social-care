import Foundation
import SQLKit

struct AddRegistrationFields: Migration {
    let name = "2026_03_04_AddRegistrationFields"

    func prepare(on db: any SQLDatabase) async throws {
        let jsonbType = SQLRaw("JSONB")
        let booleanType = SQLRaw("BOOLEAN")

        // 1. Colunas adicionadas à tabela patients
        try await db.alter(table: "patients")
            .column("personal_data", type: .custom(jsonbType))
            .run()
        try await db.alter(table: "patients")
            .column("civil_documents", type: .custom(jsonbType))
            .run()
        try await db.alter(table: "patients")
            .column("address", type: .custom(jsonbType))
            .run()
        try await db.alter(table: "patients")
            .column("social_identity", type: .custom(jsonbType))
            .run()

        // 2. Colunas adicionadas à tabela family_members
        try await db.alter(table: "family_members")
            .column("has_disability", type: .custom(booleanType), .notNull, .default(SQLLiteral.boolean(false)))
            .run()
        try await db.alter(table: "family_members")
            .column("required_documents", type: .custom(jsonbType), .notNull, .default(SQLRaw("'[]'::jsonb")))
            .run()
        try await db.alter(table: "family_members")
            .column("birth_date", type: .custom(SQLRaw("TIMESTAMP")), .notNull, .default(SQLRaw("CURRENT_TIMESTAMP")))
            .run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.alter(table: "family_members").dropColumn("birth_date").run()
        try await db.alter(table: "family_members").dropColumn("required_documents").run()
        try await db.alter(table: "family_members").dropColumn("has_disability").run()
        try await db.alter(table: "patients").dropColumn("social_identity").run()
        try await db.alter(table: "patients").dropColumn("address").run()
        try await db.alter(table: "patients").dropColumn("civil_documents").run()
        try await db.alter(table: "patients").dropColumn("personal_data").run()
    }
}
