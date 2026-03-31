import Testing
import Foundation
@testable import social_care_s

@Suite("CreateLookupItem Command Handler")
struct CreateLookupItemTests {

    @Test("Deve criar item com sucesso")
    func successfulCreation() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = CreateLookupItemCommandHandler(repository: repo)

        let id = try await handler.handle(CreateLookupItemCommand(
            tableName: "dominio_parentesco",
            codigo: "PADRASTO",
            descricao: "Padrasto",
            actorId: "admin-1"
        ))

        #expect(!id.isEmpty)
        let items = await repo.allItems(table: "dominio_parentesco")
        #expect(items.count == 1)
        #expect(items.first?.codigo == "PADRASTO")
    }

    @Test("Deve falhar com tabela nao permitida")
    func invalidTable() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = CreateLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(CreateLookupItemCommand(
                tableName: "tabela_invalida",
                codigo: "TESTE",
                descricao: "Teste",
                actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar com codigo em formato invalido")
    func invalidCodeFormat() async throws {
        let repo = InMemoryLookupAdminRepository()
        let handler = CreateLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(CreateLookupItemCommand(
                tableName: "dominio_parentesco",
                codigo: "codigo invalido",
                descricao: "Teste",
                actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar com codigo duplicado")
    func duplicateCode() async throws {
        let repo = InMemoryLookupAdminRepository()
        await repo.seedItem(table: "dominio_parentesco", id: UUID(), codigo: "PAI", descricao: "Pai")
        let handler = CreateLookupItemCommandHandler(repository: repo)

        await #expect(throws: LookupAdminError.self) {
            try await handler.handle(CreateLookupItemCommand(
                tableName: "dominio_parentesco",
                codigo: "PAI",
                descricao: "Pai duplicado",
                actorId: "admin-1"
            ))
        }
    }
}
