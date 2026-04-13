import Foundation

/// Payload de entrada para o desligamento de um paciente.
public struct DischargePatientCommand: Command {
    public let patientId: String
    public let reason: String
    public let notes: String?
    public let actorId: String

    public init(patientId: String, reason: String, notes: String?, actorId: String) {
        self.patientId = patientId
        self.reason = reason
        self.notes = notes
        self.actorId = actorId
    }
}
