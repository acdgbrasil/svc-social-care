import Foundation

public struct RejectLookupRequestCommand: Command {
    public let requestId: String
    public let reviewNote: String
    public let actorId: String

    public init(requestId: String, reviewNote: String, actorId: String) {
        self.requestId = requestId
        self.reviewNote = reviewNote
        self.actorId = actorId
    }
}
