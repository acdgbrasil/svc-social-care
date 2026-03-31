import SQLKit

struct CreateLookupRequests: Migration {
    let name = "2026_03_30_CreateLookupRequests"

    func prepare(on db: any SQLDatabase) async throws {
        let uuidType = SQLRaw("UUID")
        let timestampType = SQLRaw("TIMESTAMP")

        try await db.create(table: "lookup_requests")
            .column("id", type: .custom(uuidType), .notNull, .primaryKey(autoIncrement: false))
            .column("table_name", type: .text, .notNull)
            .column("codigo", type: .text, .notNull)
            .column("descricao", type: .text, .notNull)
            .column("justificativa", type: .text, .notNull)
            .column("status", type: .text, .notNull, .default(SQLLiteral.string("pendente")))
            .column("requested_by", type: .text, .notNull)
            .column("requested_at", type: .custom(timestampType), .notNull)
            .column("reviewed_by", type: .text)
            .column("reviewed_at", type: .custom(timestampType))
            .column("review_note", type: .text)
            .run()

        try await db.raw("CREATE INDEX idx_lookup_requests_status ON lookup_requests(status, requested_at)").run()
        try await db.raw("CREATE INDEX idx_lookup_requests_requester ON lookup_requests(requested_by)").run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.drop(table: "lookup_requests").run()
    }
}
