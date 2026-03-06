import Foundation

/// O payload de entrada para o caso de uso de atribuição de cuidador principal.
public struct AssignPrimaryCaregiverCommand: Command {
    public let patientId: String
    public let memberPersonId: String
    
    public init(patientId: String, memberPersonId: String) {
        self.patientId = patientId
        self.memberPersonId = memberPersonId
    }
}
