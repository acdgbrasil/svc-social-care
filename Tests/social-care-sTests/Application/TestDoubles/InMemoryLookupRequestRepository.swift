import Foundation
@testable import social_care_s

actor InMemoryLookupRequestRepository: LookupRequestRepository {
    private var storage: [UUID: LookupRequestRecord] = [:]

    func save(_ request: LookupRequestRecord) async throws {
        storage[request.id] = request
    }

    func findById(_ id: UUID) async throws -> LookupRequestRecord? {
        storage[id]
    }

    func list(status: String?, requestedBy: String?) async throws -> [LookupRequestRecord] {
        var results = Array(storage.values)
        if let status {
            results = results.filter { $0.status.rawValue == status }
        }
        if let requestedBy {
            results = results.filter { $0.requestedBy == requestedBy }
        }
        return results.sorted { $0.requestedAt > $1.requestedAt }
    }

    func updateStatus(_ id: UUID, status: LookupRequestStatus, reviewedBy: String,
                      reviewNote: String?) async throws {
        guard let existing = storage[id] else { return }
        storage[id] = LookupRequestRecord(
            id: existing.id,
            tableName: existing.tableName,
            codigo: existing.codigo,
            descricao: existing.descricao,
            justificativa: existing.justificativa,
            status: status,
            requestedBy: existing.requestedBy,
            requestedAt: existing.requestedAt,
            reviewedBy: reviewedBy,
            reviewedAt: Date(),
            reviewNote: reviewNote
        )
    }

    // MARK: - Test Helpers

    func allRequests() -> [LookupRequestRecord] {
        Array(storage.values)
    }

    func getRequest(_ id: UUID) -> LookupRequestRecord? {
        storage[id]
    }
}
