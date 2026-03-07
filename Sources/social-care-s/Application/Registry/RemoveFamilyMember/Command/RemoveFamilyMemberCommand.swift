import Foundation

/// Payload de entrada para a remoção de um membro familiar.
public struct RemoveFamilyMemberCommand: Command {
    public let patientId: String
    public let memberId: String
    public let actorId: String

    public init(patientId: String, memberId: String, actorId: String) {
        self.patientId = patientId
        self.memberId = memberId
        self.actorId = actorId
    }
}
