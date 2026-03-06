import Foundation

/// Payload de entrada para a remoção de um membro familiar.
public struct RemoveFamilyMemberCommand: Command {
    public let patientId: String
    public let memberId: String
    
    public init(patientId: String, memberId: String) {
        self.patientId = patientId
        self.memberId = memberId
    }
}
