import Testing
import Foundation
@testable import social_care_s

@Suite("ToggleLookupItem Command Handler")
struct ToggleLookupItemTests {

    @Test("Deve alternar ativo com sucesso")
    func successfulToggle() async throws {
        let repo = InMemoryLookupAdminRepository()
        let itemId = UUID()
        await repo.seedItem(table: "dominio_parentesco", id: itemId, codigo: "PAI", descricao: "Pai")
        let handler = ToggleLookupItemCommandHandler(repository: repo)

        try await handler.handle(ToggleLookupItemCommand(
            tableName: "dominio_parentesco", itemId: itemId.uuidString, actorId: "admin-1"
        ))

        let item = await repo.getItem(table: "dominio_parentesco", id: itemId)
        #expect(item?.ativo == false)
    }

    @Test("Deve falhar quando item referenciado por pacientes")
    func itemReferenced() async throws {
        let repo = InMemoryLookupAdminRepository()
        let itemId = UUID()
        await repo.seedItem(table: "dominio_parentesco", id: itemId, codigo: "PAI", descricao: "Pai")
        await repo.markAsReferenced(table: "dominio_parentesco", id: itemId)
        let handler = ToggleLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(ToggleLookupItemCommand(
                tableName: "dominio_parentesco", itemId: itemId.uuidString, actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar quando item nao encontrado")
    func itemNotFound() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = ToggleLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(ToggleLookupItemCommand(
                tableName: "dominio_parentesco", itemId: UUID().uuidString, actorId: "admin-1"
            ))
        }
    }
}
