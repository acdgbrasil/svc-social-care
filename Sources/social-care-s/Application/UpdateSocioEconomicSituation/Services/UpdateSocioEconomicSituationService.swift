import Foundation

/// Implementação do serviço Maestro para atualização da situação socioeconômica.
struct UpdateSocioEconomicSituationService: UpdateSocioEconomicSituationUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: UpdateSocioEconomicSituationCommand) async throws(UpdateSocioEconomicSituationError) {
        do {
            // 1. Parse
            let personId = try PersonId(command.patientId)
            
            let benefits = try command.situation.socialBenefits.map { draft in
                let beneficiaryId = try PersonId(draft.beneficiaryId)
                return try SocialBenefit(
                    benefitName: draft.benefitName,
                    amount: draft.amount,
                    beneficiaryId: beneficiaryId
                )
            }
            
            let collection = try SocialBenefitsCollection(benefits)
            
            let situation = try SocioEconomicSituation(
                totalFamilyIncome: command.situation.totalFamilyIncome,
                incomePerCapita: command.situation.incomePerCapita,
                receivesSocialBenefit: command.situation.receivesSocialBenefit,
                socialBenefits: collection,
                mainSourceOfIncome: command.situation.mainSourceOfIncome,
                hasUnemployed: command.situation.hasUnemployed
            )
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: personId) else {
                throw UpdateSocioEconomicSituationError.patientNotFound
            }
            
            // 3. Domain Logic
            patient.updateSocioEconomicSituation(situation)
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
