import Testing
@testable import social_care_s
import Foundation

@Suite("HousingCondition ValueObject (FP Style - Specification)")
struct HousingConditionTests {

    @Suite("1. Criação (Factory) e Validação")
    struct CreationAndValidation {

        @Test("create valida quartos vs banheiros (banheiros > quartos deve falhar)")
        func validateBathroomsVsRooms() {
            #expect(throws: HousingConditionError.bathroomsExceedRooms) {
                try HousingCondition.create(
                    type: .owned,
                    wallMaterial: .masonry,
                    numberOfRooms: 1,
                    numberOfBathrooms: 2,
                    waterSupply: .publicNetwork,
                    electricityAccess: .meteredConnection,
                    sewageDisposal: .publicSewer,
                    wasteCollection: .directCollection,
                    accessibilityLevel: .fullyAccessible,
                    isInGeographicRiskArea: false,
                    isInSocialConflictArea: false
                )
            }
        }

        @Test("create valida números negativos (quartos < 0 deve falhar)")
        func validateNegativeRooms() {
            #expect(throws: HousingConditionError.negativeRooms) {
                try HousingCondition.create(
                    type: .owned,
                    wallMaterial: .masonry,
                    numberOfRooms: -1,
                    numberOfBathrooms: 0,
                    waterSupply: .publicNetwork,
                    electricityAccess: .meteredConnection,
                    sewageDisposal: .publicSewer,
                    wasteCollection: .directCollection,
                    accessibilityLevel: .fullyAccessible,
                    isInGeographicRiskArea: false,
                    isInSocialConflictArea: false
                )
            }
        }
        
        @Test("cria HousingCondition válida")
        func createValid() throws {
            let _ = try HousingCondition.create(
                type: .owned,
                wallMaterial: .masonry,
                numberOfRooms: 3,
                numberOfBathrooms: 1,
                waterSupply: .publicNetwork,
                electricityAccess: .meteredConnection,
                sewageDisposal: .publicSewer,
                wasteCollection: .directCollection,
                accessibilityLevel: .fullyAccessible,
                isInGeographicRiskArea: false,
                isInSocialConflictArea: false
            )
        }
    }
}
