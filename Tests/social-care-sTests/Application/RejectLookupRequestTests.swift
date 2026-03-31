import Testing
import Foundation
@testable import social_care_s

@Suite("RejectLookupRequest Command Handler")
struct RejectLookupRequestTests {

    private static func makePendingRequest() -> LookupRequestRecord {
        LookupRequestRecord(
            id: UUID(),
            tableName: "dominio_parentesco",
            codigo: "PADRASTO",
            descricao: "Padrasto",
            justificativa: "Necessario",
            status: .pendente,
            requestedBy: "sw-1",
            requestedAt: Date()
        )
    }

    @Test("Deve rejeitar com sucesso")
    func successfulRejection() async throws {
        let repo = InMemoryLookupRequestRepository()
        let request = Self.makePendingRequest()
        try await repo.save(request)
        let handler = RejectLookupRequestCommandHandler(repository: repo)

        try await handler.handle(RejectLookupRequestCommand(
            requestId: request.id.uuidString,
            reviewNote: "Ja existe parentesco similar",
            actorId: "admin-1"
        ))

        let updated = await repo.getRequest(request.id)
        #expect(updated?.status == .rejeitado)
        #expect(updated?.reviewNote == "Ja existe parentesco similar")
        #expect(updated?.reviewedBy == "admin-1")
    }

    @Test("Deve falhar com nota de revisao vazia")
    func emptyReviewNote() async throws {
        let repo = InMemoryLookupRequestRepository()
        let request = Self.makePendingRequest()
        try await repo.save(request)
        let handler = RejectLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(RejectLookupRequestCommand(
                requestId: request.id.uuidString,
                reviewNote: "  ",
                actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar quando request ja revisada")
    func alreadyReviewed() async throws {
        let repo = InMemoryLookupRequestRepository()
        let request = Self.makePendingRequest()
        try await repo.save(request)
        try await repo.updateStatus(request.id, status: .aprovado, reviewedBy: "admin-0", reviewNote: nil)
        let handler = RejectLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(RejectLookupRequestCommand(
                requestId: request.id.uuidString,
                reviewNote: "Motivo",
                actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar quando request nao encontrada")
    func requestNotFound() async throws {
        let repo = InMemoryLookupRequestRepository()
        let handler = RejectLookupRequestCommandHandler(repository: repo)

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(RejectLookupRequestCommand(
                requestId: UUID().uuidString,
                reviewNote: "Motivo",
                actorId: "admin-1"
            ))
        }
    }
}
