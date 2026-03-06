import Foundation

/// Payload de entrada para atualização da identidade social de um paciente.
public struct UpdateSocialIdentityCommand: Command {
    public let patientId: String
    public let typeId: String
    public let description: String?

    public init(patientId: String, typeId: String, description: String?) {
        self.patientId = patientId
        self.typeId = typeId
        self.description = description
    }
}
