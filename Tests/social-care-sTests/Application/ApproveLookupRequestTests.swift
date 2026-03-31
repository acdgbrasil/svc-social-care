import Testing
import Foundation
@testable import social_care_s

@Suite("ApproveLookupRequest Command Handler")
struct ApproveLookupRequestTests {

    private static func makePendingRequest(
        tableName: String = "dominio_parentesco",
        codigo: String = "PADRASTO"
    ) -> LookupRequestRecord {
        LookupRequestRecord(
            id: UUID(),
            tableName: tableName,
            codigo: codigo,
            descricao: "Padrasto",
            justificativa: "Necessario",
            status: .pendente,
            requestedBy: "sw-1",
            requestedAt: Date()
        )
    }

    @Test("Deve aprovar e criar item automaticamente")
    func successfulApproval() async throws {
        let requestRepo = InMemoryLookupRequestRepository()
        let lookupRepo = InMemoryLookupAdminRepository()
        let request = Self.makePendingRequest()
        try await requestRepo.save(request)
        let handler = ApproveLookupRequestCommandHandler(
            requestRepository: requestRepo, lookupRepository: lookupRepo
        )

        try await handler.handle(ApproveLookupRequestCommand(
            requestId: request.id.uuidString, actorId: "admin-1"
        ))

        let updated = await requestRepo.getRequest(request.id)
        #expect(updated?.status == .aprovado)
        #expect(updated?.reviewedBy == "admin-1")

        let items = await lookupRepo.allItems(table: "dominio_parentesco")
        #expect(items.count == 1)
        #expect(items.first?.codigo == "PADRASTO")
    }

    @Test("Deve falhar quando request ja foi revisada")
    func alreadyReviewed() async throws {
        let requestRepo = InMemoryLookupRequestRepository()
        let lookupRepo = InMemoryLookupAdminRepository()
        let request = Self.makePendingRequest()
        try await requestRepo.save(request)
        try await requestRepo.updateStatus(request.id, status: .rejeitado, reviewedBy: "admin-0", reviewNote: "nao")
        let handler = ApproveLookupRequestCommandHandler(
            requestRepository: requestRepo, lookupRepository: lookupRepo
        )

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(ApproveLookupRequestCommand(
                requestId: request.id.uuidString, actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar quando codigo ja existe na tabela")
    func codigoAlreadyExists() async throws {
        let requestRepo = InMemoryLookupRequestRepository()
        let lookupRepo = InMemoryLookupAdminRepository()
        let request = Self.makePendingRequest(codigo: "PAI")
        try await requestRepo.save(request)
        await lookupRepo.seedItem(table: "dominio_parentesco", id: UUID(), codigo: "PAI", descricao: "Pai")
        let handler = ApproveLookupRequestCommandHandler(
            requestRepository: requestRepo, lookupRepository: lookupRepo
        )

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(ApproveLookupRequestCommand(
                requestId: request.id.uuidString, actorId: "admin-1"
            ))
        }
    }

    @Test("Deve falhar quando request nao encontrada")
    func requestNotFound() async throws {
        let requestRepo = InMemoryLookupRequestRepository()
        let lookupRepo = InMemoryLookupAdminRepository()
        let handler = ApproveLookupRequestCommandHandler(
            requestRepository: requestRepo, lookupRepository: lookupRepo
        )

        await #expect(throws: LookupRequestError.self) {
            try await handler.handle(ApproveLookupRequestCommand(
                requestId: UUID().uuidString, actorId: "admin-1"
            ))
        }
    }
}
