import Foundation

/// Port for validating that a PersonId exists in the people-context service.
/// Injected into RegisterPatientCommandHandler as an optional dependency.
public protocol PersonExistenceValidating: Sendable {
    /// Returns true if the given PersonId is registered in people-context.
    func exists(personId: PersonId) async throws -> Bool
}
