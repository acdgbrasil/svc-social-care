import Foundation

/// Payload de entrada para a admissao de um paciente.
public struct AdmitPatientCommand: Command {
    public let patientId: String
    public let actorId: String

    public init(patientId: String, actorId: String) {
        self.patientId = patientId
        self.actorId = actorId
    }
}
