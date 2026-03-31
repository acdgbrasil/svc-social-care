import Foundation

public struct ApproveLookupRequestCommand: Command {
    public let requestId: String
    public let actorId: String

    public init(requestId: String, actorId: String) {
        self.requestId = requestId
        self.actorId = actorId
    }
}
