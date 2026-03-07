import Foundation

/// Payload de entrada para a criação de um encaminhamento.
public struct CreateReferralCommand: ResultCommand {
    public typealias Result = String
    
    public let patientId: String
    public let referredPersonId: String
    public let professionalId: String?
    public let destinationService: String
    public let reason: String
    public let date: Date?
    public let actorId: String

    public init(
        patientId: String,
        referredPersonId: String,
        professionalId: String? = nil,
        destinationService: String,
        reason: String,
        date: Date? = nil,
        actorId: String
    ) {
        self.patientId = patientId
        self.referredPersonId = referredPersonId
        self.professionalId = professionalId
        self.destinationService = destinationService
        self.reason = reason
        self.date = date
        self.actorId = actorId
    }
}
