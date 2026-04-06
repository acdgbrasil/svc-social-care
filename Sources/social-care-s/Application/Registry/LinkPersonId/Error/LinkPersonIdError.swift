import Foundation

/// Errors for the LinkPersonId use case.
public enum LinkPersonIdError: Error, Sendable {
    case invalidCpf(String)
    case invalidPersonId(String)
    case patientNotFound(cpf: String)
    case alreadyLinked(patientId: String, existingPersonId: String)
}
