import Foundation

/// Contrato do Query Orchestrator para o fluxo de cadastro completo da pessoa de referência.
///
/// O I/O só depende deste protocolo — não conhece a topologia de use cases internos.
public protocol PatientRegistering: Sendable {
    func register(request: PatientRegistrationRequest) async throws -> PatientRegistrationResult
}
