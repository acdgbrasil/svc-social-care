import Foundation

/// Payload de entrada para a criação de um encaminhamento.
struct CreateReferralCommand: Sendable {
    let patientId: String
    let referredPersonId: String
    let professionalId: String?
    let destinationService: String
    let reason: String
    let date: Date?
    
    init(
        patientId: String,
        referredPersonId: String,
        professionalId: String? = nil,
        destinationService: String,
        reason: String,
        date: Date? = nil
    ) {
        self.patientId = patientId
        self.referredPersonId = referredPersonId
        self.professionalId = professionalId
        self.destinationService = destinationService
        self.reason = reason
        self.date = date
    }
}
