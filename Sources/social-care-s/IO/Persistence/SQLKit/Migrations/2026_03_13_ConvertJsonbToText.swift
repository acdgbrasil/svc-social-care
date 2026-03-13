import SQLKit

/// Converte colunas JSONB que são tratadas como String no Swift para TEXT,
/// eliminando o mismatch de tipo no bind do PostgresKit (.model() envia TEXT, coluna espera JSONB).
struct ConvertJsonbToText: Migration {
    let name = "2026_03_13_ConvertJsonbToText"

    func prepare(on db: any SQLDatabase) async throws {
        try await db.raw("ALTER TABLE family_members ALTER COLUMN required_documents TYPE TEXT USING required_documents::text").run()
        try await db.raw("ALTER TABLE patients ALTER COLUMN shs_functional_dependencies TYPE TEXT USING shs_functional_dependencies::text").run()
        try await db.raw("ALTER TABLE patients ALTER COLUMN hs_constant_care_member_ids TYPE TEXT USING hs_constant_care_member_ids::text").run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.raw("ALTER TABLE family_members ALTER COLUMN required_documents TYPE JSONB USING required_documents::jsonb").run()
        try await db.raw("ALTER TABLE patients ALTER COLUMN shs_functional_dependencies TYPE JSONB USING shs_functional_dependencies::jsonb").run()
        try await db.raw("ALTER TABLE patients ALTER COLUMN hs_constant_care_member_ids TYPE JSONB USING hs_constant_care_member_ids::jsonb").run()
    }
}
