import Foundation
/// Serviço que implementa a lógica de negócio para adicionar um membro familiar a um paciente.
struct AddFamilyMemberService: AddFamilyMemberUseCase, Sendable {
    private let patientRepository: PatientRepository
    private let eventBus: EventBus
    
    /// Inicializa o serviço com suas dependências obrigatórias.
    init(patientRepository: PatientRepository, eventBus: EventBus) {
        self.patientRepository = patientRepository
        self.eventBus = eventBus
    }
    
    /// Executa o caso de uso de adição de membro familiar.
    /// - Parameter command: Os dados necessários para a operação.
    /// - Throws: `AddFamilyMemberError` em caso de falha na validação ou persistência.
    func execute(command: AddFamilyMemberCommand) async throws(AddFamilyMemberError) {
        do {
            // 1. Parse
            let patientPersonId = try PersonId(command.patientPersonId)
            let memberPersonId = try PersonId(command.memberPersonId)
            
            // 2. Fetch
            guard var patient = try await patientRepository.find(byPersonId: patientPersonId) else {
                throw AddFamilyMemberError.patientNotFound
            }
            
            if patient.familyMembers.contains(where: { $0.personId == memberPersonId }) {
                throw AddFamilyMemberError.personIdAlreadyExists
            }
            
            // 3. Domain Logic
            let newFamilyMember = try FamilyMember(
                personId: memberPersonId,
                relationship: command.relationship,
                isPrimaryCaregiver: command.isCaregiver,
                residesWithPatient: command.isResiding
            )
            
            try patient.addFamilyMember(newFamilyMember, now: .now)
            
            // 4. Persistence & Events
            try await patientRepository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientPersonId)
        }
    }
}
