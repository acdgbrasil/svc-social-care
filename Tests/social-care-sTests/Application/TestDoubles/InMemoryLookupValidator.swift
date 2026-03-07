import Foundation
@testable import social_care_s

actor InMemoryLookupValidator: LookupValidating {
    private var validIds: [String: Set<String>] = [:]

    func exists(id: LookupId, in table: String) async throws -> Bool {
        validIds[table]?.contains(id.description) ?? false
    }

    // MARK: - Test Helpers

    func register(id: LookupId, in table: String) {
        validIds[table, default: []].insert(id.description)
    }

    func registerAll(ids: [LookupId], in table: String) {
        for id in ids {
            validIds[table, default: []].insert(id.description)
        }
    }

    nonisolated func allowAll() -> AllowAllLookupValidator {
        AllowAllLookupValidator()
    }
}

struct AllowAllLookupValidator: LookupValidating {
    func exists(id: LookupId, in table: String) async throws -> Bool {
        true
    }
}
