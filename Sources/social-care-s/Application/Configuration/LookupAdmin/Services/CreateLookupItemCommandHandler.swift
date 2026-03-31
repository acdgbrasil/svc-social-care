import Foundation

public actor CreateLookupItemCommandHandler: ResultCommandHandling {
    public typealias C = CreateLookupItemCommand
    private let repository: any LookupRepository

    public init(repository: any LookupRepository) {
        self.repository = repository
    }

    public func handle(_ command: CreateLookupItemCommand) async throws -> String {
        guard AllowedLookupTables.all.contains(command.tableName) else {
            throw LookupAdminError.tableNotAllowed(command.tableName)
        }

        let code: LookupItemCode
        do { code = try LookupItemCode(command.codigo) }
        catch { throw LookupAdminError.invalidCodigoFormat(command.codigo) }

        if try await repository.codigoExists(in: command.tableName, codigo: code.value) {
            throw LookupAdminError.codigoAlreadyExists(table: command.tableName, codigo: code.value)
        }

        let id = UUID()
        try await repository.createItem(
            in: command.tableName,
            id: id,
            codigo: code.value,
            descricao: command.descricao,
            metadata: command.metadata
        )

        return id.uuidString
    }
}
