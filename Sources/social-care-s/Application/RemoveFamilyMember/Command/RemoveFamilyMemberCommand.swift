import Foundation

/// Payload de entrada para a remoção de um membro familiar.
struct RemoveFamilyMemberCommand: Sendable {
    let patientId: String
    let memberPersonId: String
    
    init(patientId: String, memberPersonId: String) {
        self.patientId = patientId
        self.memberPersonId = memberPersonId
    }
}
