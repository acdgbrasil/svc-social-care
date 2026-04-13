import Foundation

/// Implementação do serviço para desligamento de pacientes.
public actor DischargePatientCommandHandler: DischargePatientUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: DischargePatientCommand) async throws {
        do {
            // 1. Parse
            let patientId = try PatientId(command.patientId)

            guard let reason = DischargeReason(rawValue: command.reason) else {
                throw DischargePatientError.invalidReason(command.reason)
            }

            // 2. Fetch
            guard var patient = try await repository.find(byId: patientId) else {
                throw DischargePatientError.patientNotFound(command.patientId)
            }

            // 3. Domain
            try patient.discharge(reason: reason, notes: command.notes, actorId: command.actorId)

            // 4. Persist
            try await repository.save(patient)

            // 5. Publish events
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
