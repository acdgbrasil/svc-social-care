import Foundation

public struct CreateLookupItemCommand: ResultCommand {
    public typealias Result = String

    public let tableName: String
    public let codigo: String
    public let descricao: String
    public let metadata: LookupItemMetadata?
    public let actorId: String

    public init(
        tableName: String,
        codigo: String,
        descricao: String,
        metadata: LookupItemMetadata? = nil,
        actorId: String
    ) {
        self.tableName = tableName
        self.codigo = codigo
        self.descricao = descricao
        self.metadata = metadata
        self.actorId = actorId
    }
}
