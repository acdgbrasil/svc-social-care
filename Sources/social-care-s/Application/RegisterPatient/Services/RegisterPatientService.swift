import Foundation

/// Implementação do serviço Maestro para registro de novos pacientes.
struct RegisterPatientService: RegisterPatientUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: RegisterPatientCommand) async throws(RegisterPatientError) -> String {
        do {
            // 1. Parse
            let personId = try PersonId(command.personId)
            let diagnoses = try command.initialDiagnoses.map { draft in
                let icd = try ICDCode(draft.icdCode)
                let date = try TimeStamp(draft.date)
                return try Diagnosis(id: icd, date: date, description: draft.description, now: .now)
            }
            
            // 2. Existence Check
            if try await repository.exists(byPersonId: personId) {
                throw RegisterPatientError.personIdAlreadyExists
            }
            
            // 3. Domain Logic
            let patient = try Patient(
                id: PatientId(),
                personId: personId,
                diagnoses: diagnoses,
                now: .now
            )
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
            return patient.id.description
            
        } catch {
            throw mapError(error, patientId: command.personId)
        }
    }
}
