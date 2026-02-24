import Foundation

/// Implementação do serviço Maestro para atribuição de cuidador principal.
struct AssignPrimaryCaregiverService: AssignPrimaryCaregiverUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: AssignPrimaryCaregiverCommand) async throws(AssignPrimaryCaregiverError) {
        do {
            // 1. Parse
            let patientPersonId = try PersonId(command.patientId)
            let memberPersonId = try PersonId(command.memberPersonId)
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: patientPersonId) else {
                throw AssignPrimaryCaregiverError.patientNotFound
            }
            
            // 3. Domain Logic
            try patient.assignPrimaryCaregiver(personId: memberPersonId)
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
