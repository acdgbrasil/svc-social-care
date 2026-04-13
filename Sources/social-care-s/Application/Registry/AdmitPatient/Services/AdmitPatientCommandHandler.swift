import Foundation

/// Implementacao do servico para admissao de pacientes.
public actor AdmitPatientCommandHandler: AdmitPatientUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: AdmitPatientCommand) async throws {
        do {
            // 1. Parse
            let patientId = try PatientId(command.patientId)

            // 2. Fetch
            guard var patient = try await repository.find(byId: patientId) else {
                throw AdmitPatientError.patientNotFound(command.patientId)
            }

            // 3. Domain
            try patient.admit(actorId: command.actorId)

            // 4. Persist
            try await repository.save(patient)

            // 5. Publish events
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
