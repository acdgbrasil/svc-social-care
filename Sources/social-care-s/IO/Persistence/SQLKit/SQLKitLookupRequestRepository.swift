import Foundation
import SQLKit

struct SQLKitLookupRequestRepository: LookupRequestRepository {
    private let db: any SQLDatabase

    init(db: any SQLDatabase) {
        self.db = db
    }

    func save(_ request: LookupRequestRecord) async throws {
        try await db.insert(into: "lookup_requests")
            .columns("id", "table_name", "codigo", "descricao", "justificativa",
                     "status", "requested_by", "requested_at")
            .values(
                SQLBind(request.id),
                SQLBind(request.tableName),
                SQLBind(request.codigo),
                SQLBind(request.descricao),
                SQLBind(request.justificativa),
                SQLBind(request.status.rawValue),
                SQLBind(request.requestedBy),
                SQLBind(request.requestedAt)
            )
            .run()
    }

    func findById(_ id: UUID) async throws -> LookupRequestRecord? {
        guard let row = try await db.select()
            .column("*")
            .from("lookup_requests")
            .where("id", .equal, id)
            .first(decoding: LookupRequestModel.self)
        else { return nil }

        return row.toDomain()
    }

    func list(status: String?, requestedBy: String?) async throws -> [LookupRequestRecord] {
        var query = db.select()
            .column("*")
            .from("lookup_requests")

        if let status {
            query = query.where("status", .equal, status)
        }
        if let requestedBy {
            query = query.where("requested_by", .equal, requestedBy)
        }

        let rows = try await query
            .orderBy("requested_at", .descending)
            .all(decoding: LookupRequestModel.self)

        return rows.map { $0.toDomain() }
    }

    func updateStatus(_ id: UUID, status: LookupRequestStatus, reviewedBy: String,
                      reviewNote: String?) async throws {
        try await db.update("lookup_requests")
            .set("status", to: status.rawValue)
            .set("reviewed_by", to: reviewedBy)
            .set("reviewed_at", to: Date())
            .set("review_note", to: reviewNote)
            .where("id", .equal, id)
            .run()
    }
}

// MARK: - Database Model

private struct LookupRequestModel: Codable {
    let id: UUID
    let table_name: String
    let codigo: String
    let descricao: String
    let justificativa: String
    let status: String
    let requested_by: String
    let requested_at: Date
    let reviewed_by: String?
    let reviewed_at: Date?
    let review_note: String?

    func toDomain() -> LookupRequestRecord {
        LookupRequestRecord(
            id: id,
            tableName: table_name,
            codigo: codigo,
            descricao: descricao,
            justificativa: justificativa,
            status: LookupRequestStatus(rawValue: status) ?? .pendente,
            requestedBy: requested_by,
            requestedAt: requested_at,
            reviewedBy: reviewed_by,
            reviewedAt: reviewed_at,
            reviewNote: review_note
        )
    }
}
