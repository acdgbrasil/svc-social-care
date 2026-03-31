import Foundation
@testable import social_care_s

actor InMemoryLookupAdminRepository: LookupRepository {
    private var storage: [String: [(id: UUID, codigo: String, descricao: String, ativo: Bool)]] = [:]
    private var referencedItems: Set<String> = []

    func codigoExists(in table: String, codigo: String) async throws -> Bool {
        storage[table]?.contains { $0.codigo == codigo } ?? false
    }

    func itemExists(in table: String, id: UUID) async throws -> Bool {
        storage[table]?.contains { $0.id == id } ?? false
    }

    func isItemReferenced(in table: String, id: UUID) async throws -> Bool {
        referencedItems.contains("\(table):\(id.uuidString)")
    }

    func createItem(in table: String, id: UUID, codigo: String, descricao: String,
                    metadata: LookupItemMetadata?) async throws {
        storage[table, default: []].append((id: id, codigo: codigo, descricao: descricao, ativo: true))
    }

    func updateDescription(in table: String, id: UUID, descricao: String) async throws {
        guard let idx = storage[table]?.firstIndex(where: { $0.id == id }) else { return }
        let item = storage[table]![idx]
        storage[table]![idx] = (id: item.id, codigo: item.codigo, descricao: descricao, ativo: item.ativo)
    }

    func toggleActive(in table: String, id: UUID) async throws {
        guard let idx = storage[table]?.firstIndex(where: { $0.id == id }) else { return }
        let item = storage[table]![idx]
        storage[table]![idx] = (id: item.id, codigo: item.codigo, descricao: item.descricao, ativo: !item.ativo)
    }

    // MARK: - Test Helpers

    func seedItem(table: String, id: UUID, codigo: String, descricao: String, ativo: Bool = true) {
        storage[table, default: []].append((id: id, codigo: codigo, descricao: descricao, ativo: ativo))
    }

    func markAsReferenced(table: String, id: UUID) {
        referencedItems.insert("\(table):\(id.uuidString)")
    }

    func getItem(table: String, id: UUID) -> (id: UUID, codigo: String, descricao: String, ativo: Bool)? {
        storage[table]?.first { $0.id == id }
    }

    func allItems(table: String) -> [(id: UUID, codigo: String, descricao: String, ativo: Bool)] {
        storage[table] ?? []
    }
}
