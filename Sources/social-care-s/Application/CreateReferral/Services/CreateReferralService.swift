import Foundation

/// Implementação do serviço Maestro para criação de encaminhamentos.
struct CreateReferralService: CreateReferralUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: CreateReferralCommand) async throws(CreateReferralError) -> String {
        do {
            // 1. Parse
            let patientPersonId = try PersonId(command.patientId)
            let referredPersonId = try PersonId(command.referredPersonId)
            
            let requestingProfessionalId = try command.professionalId.map { try ProfessionalId($0) } ?? ProfessionalId()
            let date = try command.date.map { try TimeStamp($0) } ?? TimeStamp.now
            
            guard let destinationService = Referral.DestinationService(rawValue: command.destinationService) else {
                throw CreateReferralError.invalidDestinationService(command.destinationService)
            }
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: patientPersonId) else {
                throw CreateReferralError.patientNotFound
            }
            
            // 3. Domain Logic
            let referralId = ReferralId()
            try patient.addReferral(
                id: referralId,
                date: date,
                requestingProfessionalId: requestingProfessionalId,
                referredPersonId: referredPersonId,
                destinationService: destinationService,
                reason: command.reason,
                now: .now
            )
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
            return referralId.description
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
