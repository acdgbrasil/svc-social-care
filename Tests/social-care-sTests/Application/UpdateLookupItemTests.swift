import Testing
import Foundation
@testable import social_care_s

@Suite("UpdateLookupItem Command Handler")
struct UpdateLookupItemTests {

    @Test("Deve atualizar descricao com sucesso")
    func successfulUpdate() async throws {
        let repo = InMemoryLookupAdminRepository()
        let itemId = UUID()
        await repo.seedItem(table: "dominio_parentesco", id: itemId, codigo: "PAI", descricao: "Pai")
        let handler = UpdateLookupItemCommandHandler(repository: repo)

        try await handler.handle(UpdateLookupItemCommand(
            tableName: "dominio_parentesco",
            itemId: itemId.uuidString,
            descricao: "Pai / Padrasto",
            actorId: "admin-1"
        ))

        let item = await repo.getItem(table: "dominio_parentesco", id: itemId)
        #expect(item?.descricao == "Pai / Padrasto")
    }

    @Test("Deve falhar quando item nao encontrado")
    func itemNotFound() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = UpdateLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(UpdateLookupItemCommand(
                tableName: "dominio_parentesco",
                itemId: UUID().uuidString,
                descricao: "Nova descricao",
                actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar com ID invalido")
    func invalidId() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = UpdateLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(UpdateLookupItemCommand(
                tableName: "dominio_parentesco",
                itemId: "not-a-uuid",
                descricao: "Nova descricao",
                actorId: "admin-1"
            ))
        }
    }
}
