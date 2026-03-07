import Foundation

/// Implementação do serviço Maestro para atribuição de cuidador principal.
public actor AssignPrimaryCaregiverCommandHandler: AssignPrimaryCaregiverUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    public func handle(_ command: AssignPrimaryCaregiverCommand) async throws {
        do {
            // 1. Parse
            let patientPersonId = try PersonId(command.patientId)
            let memberPersonId = try PersonId(command.memberPersonId)
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: patientPersonId) else {
                throw AssignPrimaryCaregiverError.patientNotFound
            }
            
            // 3. Domain Logic
            try patient.assignPrimaryCaregiver(identifiedBy: memberPersonId, actorId: command.actorId, at: TimeStamp.now)
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
