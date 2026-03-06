import Foundation

/// Payload de entrada para a atualização das condições de moradia.
public struct UpdateHousingConditionCommand: Command {
    public struct ConditionDraft: Sendable {
        public let type: String
        public let wallMaterial: String
        public let numberOfRooms: Int
        public let numberOfBedrooms: Int
        public let numberOfBathrooms: Int
        public let waterSupply: String
        public let hasPipedWater: Bool
        public let electricityAccess: String
        public let sewageDisposal: String
        public let wasteCollection: String
        public let accessibilityLevel: String
        public let isInGeographicRiskArea: Bool
        public let hasDifficultAccess: Bool
        public let isInSocialConflictArea: Bool
        public let hasDiagnosticObservations: Bool

        public init(
            type: String,
            wallMaterial: String,
            numberOfRooms: Int,
            numberOfBedrooms: Int,
            numberOfBathrooms: Int,
            waterSupply: String,
            hasPipedWater: Bool,
            electricityAccess: String,
            sewageDisposal: String,
            wasteCollection: String,
            accessibilityLevel: String,
            isInGeographicRiskArea: Bool,
            hasDifficultAccess: Bool,
            isInSocialConflictArea: Bool,
            hasDiagnosticObservations: Bool
        ) {
            self.type = type
            self.wallMaterial = wallMaterial
            self.numberOfRooms = numberOfRooms
            self.numberOfBedrooms = numberOfBedrooms
            self.numberOfBathrooms = numberOfBathrooms
            self.waterSupply = waterSupply
            self.hasPipedWater = hasPipedWater
            self.electricityAccess = electricityAccess
            self.sewageDisposal = sewageDisposal
            self.wasteCollection = wasteCollection
            self.accessibilityLevel = accessibilityLevel
            self.isInGeographicRiskArea = isInGeographicRiskArea
            self.hasDifficultAccess = hasDifficultAccess
            self.isInSocialConflictArea = isInSocialConflictArea
            self.hasDiagnosticObservations = hasDiagnosticObservations
        }
    }
    
    public let patientId: String
    public let condition: ConditionDraft
    
    public init(patientId: String, condition: ConditionDraft) {
        self.patientId = patientId
        self.condition = condition
    }
}
