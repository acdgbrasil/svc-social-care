import Foundation

/// Implementação do serviço Maestro para atualização das condições de moradia.
struct UpdateHousingConditionService: UpdateHousingConditionUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: UpdateHousingConditionCommand) async throws(UpdateHousingConditionError) {
        do {
            // 1. Parse
            let personId = try PersonId(command.patientId)
            
            guard let type = HousingCondition.ConditionType(rawValue: command.condition.type) else {
                throw UpdateHousingConditionError.invalidHousingType(command.condition.type)
            }
            guard let wall = HousingCondition.WallMaterial(rawValue: command.condition.wallMaterial) else {
                throw UpdateHousingConditionError.invalidWallMaterial(command.condition.wallMaterial)
            }
            guard let water = HousingCondition.WaterSupply(rawValue: command.condition.waterSupply) else {
                throw UpdateHousingConditionError.invalidWaterSupply(command.condition.waterSupply)
            }
            guard let electricity = HousingCondition.ElectricityAccess(rawValue: command.condition.electricityAccess) else {
                throw UpdateHousingConditionError.invalidElectricityAccess(command.condition.electricityAccess)
            }
            guard let sewage = HousingCondition.SewageDisposal(rawValue: command.condition.sewageDisposal) else {
                throw UpdateHousingConditionError.invalidSewageDisposal(command.condition.sewageDisposal)
            }
            guard let waste = HousingCondition.WasteCollection(rawValue: command.condition.wasteCollection) else {
                throw UpdateHousingConditionError.invalidWasteCollection(command.condition.wasteCollection)
            }
            guard let access = HousingCondition.AccessibilityLevel(rawValue: command.condition.accessibilityLevel) else {
                throw UpdateHousingConditionError.invalidAccessibilityLevel(command.condition.accessibilityLevel)
            }
            
            let condition = try HousingCondition(
                type: type,
                wallMaterial: wall,
                numberOfRooms: command.condition.numberOfRooms,
                numberOfBathrooms: command.condition.numberOfBathrooms,
                waterSupply: water,
                electricityAccess: electricity,
                sewageDisposal: sewage,
                wasteCollection: waste,
                accessibilityLevel: access,
                isInGeographicRiskArea: command.condition.isInGeographicRiskArea,
                isInSocialConflictArea: command.condition.isInSocialConflictArea
            )
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: personId) else {
                throw UpdateHousingConditionError.patientNotFound
            }
            
            // 3. Domain Logic
            patient.updateHousingCondition(condition)
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
