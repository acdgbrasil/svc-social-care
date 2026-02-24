import Foundation

/// Payload de entrada para a atualização das condições de moradia.
struct UpdateHousingConditionCommand: Sendable {
    struct ConditionDraft: Sendable {
        let type: String
        let wallMaterial: String
        let numberOfRooms: Int
        let numberOfBathrooms: Int
        let waterSupply: String
        let electricityAccess: String
        let sewageDisposal: String
        let wasteCollection: String
        let accessibilityLevel: String
        let isInGeographicRiskArea: Bool
        let isInSocialConflictArea: Bool
    }
    
    let patientId: String
    let condition: ConditionDraft
    
    init(patientId: String, condition: ConditionDraft) {
        self.patientId = patientId
        self.condition = condition
    }
}
