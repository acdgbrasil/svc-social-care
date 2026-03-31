import Foundation

public actor ApproveLookupRequestCommandHandler: CommandHandling {
    public typealias C = ApproveLookupRequestCommand
    private let requestRepository: any LookupRequestRepository
    private let lookupRepository: any LookupRepository

    public init(requestRepository: any LookupRequestRepository, lookupRepository: any LookupRepository) {
        self.requestRepository = requestRepository
        self.lookupRepository = lookupRepository
    }

    public func handle(_ command: ApproveLookupRequestCommand) async throws {
        guard let requestUUID = UUID(uuidString: command.requestId) else {
            throw LookupRequestError.invalidRequestId(command.requestId)
        }

        guard let request = try await requestRepository.findById(requestUUID) else {
            throw LookupRequestError.requestNotFound(command.requestId)
        }

        guard request.status == .pendente else {
            throw LookupRequestError.requestAlreadyReviewed(command.requestId)
        }

        if try await lookupRepository.codigoExists(in: request.tableName, codigo: request.codigo) {
            throw LookupRequestError.codigoAlreadyExists(table: request.tableName, codigo: request.codigo)
        }

        try await lookupRepository.createItem(
            in: request.tableName,
            id: UUID(),
            codigo: request.codigo,
            descricao: request.descricao,
            metadata: nil
        )

        try await requestRepository.updateStatus(
            requestUUID,
            status: .aprovado,
            reviewedBy: command.actorId,
            reviewNote: nil
        )
    }
}
