import Foundation

/// Payload de entrada para a readmissão de um paciente.
public struct ReadmitPatientCommand: Command {
    public let patientId: String
    public let notes: String?
    public let actorId: String

    public init(patientId: String, notes: String?, actorId: String) {
        self.patientId = patientId
        self.notes = notes
        self.actorId = actorId
    }
}
