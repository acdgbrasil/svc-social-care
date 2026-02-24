import Testing
@testable import social_care_s
import Foundation

@Suite("HousingCondition ValueObject")
struct HousingConditionTests {

    @Test("Valida quartos vs banheiros")
    func validateBathroomsVsRooms() {
        #expect(throws: HousingConditionError.bathroomsExceedRooms) {
            try HousingCondition(type: .owned, wallMaterial: .masonry, numberOfRooms: 1, numberOfBathrooms: 2, waterSupply: .publicNetwork, electricityAccess: .meteredConnection, sewageDisposal: .publicSewer, wasteCollection: .directCollection, accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false)
        }
    }

    @Test("Valida números negativos")
    func validateNegative() {
        #expect(throws: HousingConditionError.negativeRooms) {
            try HousingCondition(type: .owned, wallMaterial: .masonry, numberOfRooms: -1, numberOfBathrooms: 0, waterSupply: .publicNetwork, electricityAccess: .meteredConnection, sewageDisposal: .publicSewer, wasteCollection: .directCollection, accessibilityLevel: .fullyAccessible, isInGeographicRiskArea: false, isInSocialConflictArea: false)
        }
    }

    @Test("Valida conversão de HousingConditionError para AppError")
    func errorConversion() {
        #expect(HousingConditionError.negativeRooms.asAppError.code == "HC-001")
        #expect(HousingConditionError.negativeBathrooms.asAppError.code == "HC-002")
        #expect(HousingConditionError.bathroomsExceedRooms.asAppError.code == "HC-003")
    }
}
