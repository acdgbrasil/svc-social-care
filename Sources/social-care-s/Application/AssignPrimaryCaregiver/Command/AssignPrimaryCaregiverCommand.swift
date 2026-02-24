import Foundation

/// O payload de entrada para o caso de uso de atribuição de cuidador principal.
struct AssignPrimaryCaregiverCommand: Sendable {
    let patientId: String
    let memberPersonId: String
    
    init(patientId: String, memberPersonId: String) {
        self.patientId = patientId
        self.memberPersonId = memberPersonId
    }
}
