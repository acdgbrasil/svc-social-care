import Foundation

/// Command to link a Patient's person_id to the canonical PersonId from people-context.
/// Triggered by consuming `people.person.registered` events via NATS.
public struct LinkPersonIdCommand: Command, Sendable {
    /// The canonical PersonId from people-context.
    public let personId: String

    /// The CPF used to match an existing Patient.
    public let cpf: String

    /// Actor who triggered the event (usually the Zitadel userId).
    public let actorId: String

    public init(personId: String, cpf: String, actorId: String) {
        self.personId = personId
        self.cpf = cpf
        self.actorId = actorId
    }
}
