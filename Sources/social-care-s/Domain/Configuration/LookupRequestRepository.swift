import Foundation

/// Port para operacoes de solicitacoes de novos itens em lookup tables.
public protocol LookupRequestRepository: Sendable {

    /// Persiste uma nova solicitacao.
    func save(_ request: LookupRequestRecord) async throws

    /// Busca uma solicitacao por ID.
    func findById(_ id: UUID) async throws -> LookupRequestRecord?

    /// Lista solicitacoes com filtros opcionais.
    func list(status: String?, requestedBy: String?) async throws -> [LookupRequestRecord]

    /// Atualiza o status de uma solicitacao (aprovar/rejeitar).
    func updateStatus(_ id: UUID, status: LookupRequestStatus, reviewedBy: String,
                      reviewNote: String?) async throws
}
