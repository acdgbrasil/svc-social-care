import Foundation

/// DTO for decoding `people.person.registered` events from people-context via NATS.
///
/// Payload format:
/// ```json
/// {
///   "metadata": { "eventId": "...", "occurredAt": "...", "schemaVersion": "1.0.0" },
///   "actorId": "...",
///   "data": { "personId": "...", "fullName": "...", "cpf": "...", "birthDate": "..." }
/// }
/// ```
struct PersonRegisteredEvent: Codable, Sendable {
    let metadata: Metadata
    let actorId: String
    let data: PersonData

    struct Metadata: Codable, Sendable {
        let eventId: String
        let occurredAt: String
        let schemaVersion: String
    }

    struct PersonData: Codable, Sendable {
        let personId: String
        let fullName: String
        let cpf: String?
        let birthDate: String
    }
}
