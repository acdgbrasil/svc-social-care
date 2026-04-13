import Foundation

/// Implementacao do servico para retirada de pacientes da fila de espera.
public actor WithdrawFromWaitlistCommandHandler: WithdrawFromWaitlistUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus

    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }

    public func handle(_ command: WithdrawFromWaitlistCommand) async throws {
        do {
            // 1. Parse
            let patientId = try PatientId(command.patientId)

            guard let reason = WithdrawReason(rawValue: command.reason) else {
                throw WithdrawFromWaitlistError.invalidReason(command.reason)
            }

            // 2. Fetch
            guard var patient = try await repository.find(byId: patientId) else {
                throw WithdrawFromWaitlistError.patientNotFound(command.patientId)
            }

            // 3. Domain
            try patient.withdraw(reason: reason, notes: command.notes, actorId: command.actorId)

            // 4. Persist
            try await repository.save(patient)

            // 5. Publish events
            try await eventBus.publish(patient.uncommittedEvents)

        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
