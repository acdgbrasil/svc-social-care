import Foundation

public actor UpdateLookupItemCommandHandler: CommandHandling {
    public typealias C = UpdateLookupItemCommand
    private let repository: any LookupRepository

    public init(repository: any LookupRepository) {
        self.repository = repository
    }

    public func handle(_ command: UpdateLookupItemCommand) async throws {
        guard AllowedLookupTables.all.contains(command.tableName) else {
            throw LookupAdminError.tableNotAllowed(command.tableName)
        }

        guard let uuid = UUID(uuidString: command.itemId) else {
            throw LookupAdminError.invalidItemId(command.itemId)
        }

        guard try await repository.itemExists(in: command.tableName, id: uuid) else {
            throw LookupAdminError.itemNotFound(table: command.tableName, id: command.itemId)
        }

        try await repository.updateDescription(in: command.tableName, id: uuid, descricao: command.descricao)
    }
}
