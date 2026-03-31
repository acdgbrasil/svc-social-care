import Testing
import Foundation
@testable import social_care_s

@Suite("CreateLookupRequest Command Handler")
struct CreateLookupRequestTests {

    @Test("Deve criar solicitacao com sucesso")
    func successfulCreation() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = CreateLookupRequestCommandHandler(repository: repo)

        let id = try await handler.handle(CreateLookupRequestCommand(
            tableName: "dominio_parentesco",
            codigo: "PADRASTO",
            descricao: "Padrasto",
            justificativa: "Necessario para cadastro de familias recompostas",
            actorId: "social-worker-1"
        ))

        #expect(!id.isEmpty)
        let requests = await repo.allRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.status == .pendente)
        #expect(requests.first?.requestedBy == "social-worker-1")
    }

    @Test("Deve falhar com tabela invalida")
    func invalidTable() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = CreateLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(CreateLookupRequestCommand(
                tableName: "tabela_invalida",
                codigo: "TESTE",
                descricao: "Teste",
                justificativa: "Teste",
                actorId: "sw-1"
            ))
        }
    }

    @Test("Deve falhar com justificativa vazia")
    func emptyJustificativa() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = CreateLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(CreateLookupRequestCommand(
                tableName: "dominio_parentesco",
                codigo: "PADRASTO",
                descricao: "Padrasto",
                justificativa: "   ",
                actorId: "sw-1"
            ))
        }
    }

    @Test("Deve falhar com descricao vazia")
    func emptyDescricao() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = CreateLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(CreateLookupRequestCommand(
                tableName: "dominio_parentesco",
                codigo: "PADRASTO",
                descricao: "",
                justificativa: "Justificativa",
                actorId: "sw-1"
            ))
        }
    }

    @Test("Deve falhar com codigo em formato invalido")
    func invalidCodeFormat() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = CreateLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(CreateLookupRequestCommand(
                tableName: "dominio_parentesco",
                codigo: "codigo invalido",
                descricao: "Teste",
                justificativa: "Justificativa",
                actorId: "sw-1"
            ))
        }
    }
}
