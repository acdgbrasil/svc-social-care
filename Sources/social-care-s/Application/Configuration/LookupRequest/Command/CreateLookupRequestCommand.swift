import Foundation

public struct CreateLookupRequestCommand: ResultCommand {
    public typealias Result = String

    public let tableName: String
    public let codigo: String
    public let descricao: String
    public let justificativa: String
    public let actorId: String

    public init(tableName: String, codigo: String, descricao: String, justificativa: String, actorId: String) {
        self.tableName = tableName
        self.codigo = codigo
        self.descricao = descricao
        self.justificativa = justificativa
        self.actorId = actorId
    }
}
