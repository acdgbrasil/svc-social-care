import Foundation

/// Payload de entrada para a retirada de um paciente da fila de espera.
public struct WithdrawFromWaitlistCommand: Command {
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
