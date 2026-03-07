import Foundation
import SQLKit

struct CreateAuditTrail: Migration {
    let name = "2026_03_09_CreateAuditTrail"

    func prepare(on db: any SQLDatabase) async throws {
        let uuidType = SQLRaw("UUID")
        let timestampType = SQLRaw("TIMESTAMP WITH TIME ZONE")
        let jsonbType = SQLRaw("JSONB")

        try await db.create(table: "audit_trail")
            .column("id", type: .custom(uuidType), .primaryKey, .notNull)
            .column("aggregate_type", type: .text, .notNull)
            .column("aggregate_id", type: .custom(uuidType), .notNull)
            .column("event_type", type: .text, .notNull)
            .column("actor_id", type: .text)
            .column("payload", type: .custom(jsonbType), .notNull)
            .column("occurred_at", type: .custom(timestampType), .notNull)
            .column("recorded_at", type: .custom(timestampType), .notNull)
            .run()

        try await db.create(index: "idx_audit_trail_aggregate")
            .on("audit_trail")
            .column("aggregate_id")
            .column("occurred_at")
            .run()

        try await db.create(index: "idx_audit_trail_event_type")
            .on("audit_trail")
            .column("event_type")
            .run()
    }

    func revert(on db: any SQLDatabase) async throws {
        try await db.drop(table: "audit_trail").run()
    }
}
