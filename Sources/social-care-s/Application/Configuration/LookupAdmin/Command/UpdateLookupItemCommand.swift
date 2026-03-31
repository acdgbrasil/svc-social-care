import Foundation

public struct UpdateLookupItemCommand: Command {
    public let tableName: String
    public let itemId: String
    public let descricao: String
    public let actorId: String

    public init(tableName: String, itemId: String, descricao: String, actorId: String) {
        self.tableName = tableName
        self.itemId = itemId
        self.descricao = descricao
        self.actorId = actorId
    }
}
