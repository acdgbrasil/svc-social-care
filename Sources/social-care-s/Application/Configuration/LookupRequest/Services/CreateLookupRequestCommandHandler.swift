import Foundation

public actor CreateLookupRequestCommandHandler: ResultCommandHandling {
    public typealias C = CreateLookupRequestCommand
    private let repository: any LookupRequestRepository

    public init(repository: any LookupRequestRepository) {
        self.repository = repository
    }

    public func handle(_ command: CreateLookupRequestCommand) async throws -> String {
        guard AllowedLookupTables.all.contains(command.tableName) else {
            throw LookupRequestError.invalidTableName(command.tableName)
        }

        do { _ = try LookupItemCode(command.codigo) }
        catch { throw LookupRequestError.invalidCodigoFormat(command.codigo) }

        guard !command.descricao.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LookupRequestError.emptyDescricao
        }

        guard !command.justificativa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LookupRequestError.emptyJustificativa
        }

        let id = UUID()
        let record = LookupRequestRecord(
            id: id,
            tableName: command.tableName,
            codigo: command.codigo.uppercased(),
            descricao: command.descricao,
            justificativa: command.justificativa,
            status: .pendente,
            requestedBy: command.actorId,
            requestedAt: Date()
        )

        try await repository.save(record)
        return id.uuidString
    }
}
