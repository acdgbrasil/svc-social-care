import Foundation

public struct ToggleLookupItemCommand: Command {
    public let tableName: String
    public let itemId: String
    public let actorId: String

    public init(tableName: String, itemId: String, actorId: String) {
        self.tableName = tableName
        self.itemId = itemId
        self.actorId = actorId
    }
}
