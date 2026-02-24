import Foundation

/// Um Value Object que representa as condições de moradia e habitabilidade de um paciente.
///
/// Consolida informações sobre o tipo de residência, materiais de construção,
/// saneamento básico, acesso a serviços e acessibilidade.
public struct HousingCondition: Codable, Equatable, Hashable, Sendable {

    // MARK: - Nested Types

    public enum ConditionType: String, Codable, Sendable {
        case owned = "OWNED"
        case rented = "RENTED"
        case ceded = "CEDED"
        case squatted = "SQUATTED"
    }

    public enum WallMaterial: String, Codable, Sendable {
        case masonry = "MASONRY"
        case finishedWood = "FINISHED_WOOD"
        case makeshiftMaterials = "MAKESHIFT_MATERIALS"
    }

    public enum WaterSupply: String, Codable, Sendable {
        case publicNetwork = "PUBLIC_NETWORK"
        case wellOrSpring = "WELL_OR_SPRING"
        case rainwaterHarvest = "RAINWATER_HARVEST"
        case waterTruck = "WATER_TRUCK"
        case other = "OTHER"
    }

    public enum ElectricityAccess: String, Codable, Sendable {
        case meteredConnection = "METERED_CONNECTION"
        case irregularConnection = "IRREGULAR_CONNECTION"
        case noAccess = "NO_ACCESS"
    }

    public enum SewageDisposal: String, Codable, Sendable {
        case publicSewer = "PUBLIC_SEWER"
        case septicTank = "SEPTIC_TANK"
        case rudimentaryPit = "RUDIMENTARY_PIT"
        case openSewage = "OPEN_SEWAGE"
        case noBathroom = "NO_BATHROOM"
    }

    public enum WasteCollection: String, Codable, Sendable {
        case directCollection = "DIRECT_COLLECTION"
        case indirectCollection = "INDIRECT_COLLECTION"
        case noCollection = "NO_COLLECTION"
    }

    public enum AccessibilityLevel: String, Codable, Sendable {
        case fullyAccessible = "FULLY_ACCESSIBLE"
        case partiallyAccessible = "PARTIALLY_ACCESSIBLE"
        case notAccessible = "NOT_ACCESSIBLE"
    }

    // MARK: - Properties

    public let type: ConditionType
    public let wallMaterial: WallMaterial
    public let numberOfRooms: Int
    public let numberOfBathrooms: Int
    public let waterSupply: WaterSupply
    public let electricityAccess: ElectricityAccess
    public let sewageDisposal: SewageDisposal
    public let wasteCollection: WasteCollection
    public let accessibilityLevel: AccessibilityLevel
    public let isInGeographicRiskArea: Bool
    public let isInSocialConflictArea: Bool

    // MARK: - Initializer

    private init(
        type: ConditionType,
        wallMaterial: WallMaterial,
        numberOfRooms: Int,
        numberOfBathrooms: Int,
        waterSupply: WaterSupply,
        electricityAccess: ElectricityAccess,
        sewageDisposal: SewageDisposal,
        wasteCollection: WasteCollection,
        accessibilityLevel: AccessibilityLevel,
        isInGeographicRiskArea: Bool,
        isInSocialConflictArea: Bool
    ) {
        self.type = type
        self.wallMaterial = wallMaterial
        self.numberOfRooms = numberOfRooms
        self.numberOfBathrooms = numberOfBathrooms
        self.waterSupply = waterSupply
        self.electricityAccess = electricityAccess
        self.sewageDisposal = sewageDisposal
        self.wasteCollection = wasteCollection
        self.accessibilityLevel = accessibilityLevel
        self.isInGeographicRiskArea = isInGeographicRiskArea
        self.isInSocialConflictArea = isInSocialConflictArea
    }

    // MARK: - Factory Method

    /// Cria uma instância validada de `HousingCondition`.
    ///
    /// - Throws: `HousingConditionError` em caso de erro de validação.
    public static func create(
        type: ConditionType,
        wallMaterial: WallMaterial,
        numberOfRooms: Int,
        numberOfBathrooms: Int,
        waterSupply: WaterSupply,
        electricityAccess: ElectricityAccess,
        sewageDisposal: SewageDisposal,
        wasteCollection: WasteCollection,
        accessibilityLevel: AccessibilityLevel,
        isInGeographicRiskArea: Bool,
        isInSocialConflictArea: Bool
    ) throws -> HousingCondition {

        // Validação: Números negativos
        guard numberOfRooms >= 0 else {
            throw HousingConditionError.negativeRooms
        }

        guard numberOfBathrooms >= 0 else {
            throw HousingConditionError.negativeBathrooms
        }

        // Validação: Coerência (banheiros não podem exceder cômodos totais)
        guard numberOfBathrooms <= numberOfRooms else {
            throw HousingConditionError.bathroomsExceedRooms
        }

        return HousingCondition(
            type: type,
            wallMaterial: wallMaterial,
            numberOfRooms: numberOfRooms,
            numberOfBathrooms: numberOfBathrooms,
            waterSupply: waterSupply,
            electricityAccess: electricityAccess,
            sewageDisposal: sewageDisposal,
            wasteCollection: wasteCollection,
            accessibilityLevel: accessibilityLevel,
            isInGeographicRiskArea: isInGeographicRiskArea,
            isInSocialConflictArea: isInSocialConflictArea
        )
    }
}
