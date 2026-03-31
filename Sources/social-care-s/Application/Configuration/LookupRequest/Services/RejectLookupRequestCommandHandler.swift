import Foundation

public actor RejectLookupRequestCommandHandler: CommandHandling {
    public typealias C = RejectLookupRequestCommand
    private let repository: any LookupRequestRepository

    public init(repository: any LookupRequestRepository) {
        self.repository = repository
    }

    public func handle(_ command: RejectLookupRequestCommand) async throws {
        guard !command.reviewNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LookupRequestError.emptyReviewNote
        }

        guard let requestUUID = UUID(uuidString: command.requestId) else {
            throw LookupRequestError.invalidRequestId(command.requestId)
        }

        guard let request = try await repository.findById(requestUUID) else {
            throw LookupRequestError.requestNotFound(command.requestId)
        }

        guard request.status == .pendente else {
            throw LookupRequestError.requestAlreadyReviewed(command.requestId)
        }

        try await repository.updateStatus(
            requestUUID,
            status: .rejeitado,
            reviewedBy: command.actorId,
            reviewNote: command.reviewNote
        )
    }
}
