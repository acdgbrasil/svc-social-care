import Foundation

/// Implementação do serviço Maestro para remoção de membros familiares.
public actor RemoveFamilyMemberCommandHandler: RemoveFamilyMemberUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    public init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    public func handle(_ command: RemoveFamilyMemberCommand) async throws {
        do {
            // 1. Parse
            let patientId = try PatientId(command.patientId)
            let memberPersonId = try PersonId(command.memberId)
            
            // 2. Fetch (Usando find by ID interno conforme comando)
            guard var patient = try await repository.find(byId: patientId) else {
                throw RemoveFamilyMemberError.patientNotFound
            }
            
            // 3. Domain Logic
            try patient.removeMember(identifiedBy: memberPersonId, at: TimeStamp.now)
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
