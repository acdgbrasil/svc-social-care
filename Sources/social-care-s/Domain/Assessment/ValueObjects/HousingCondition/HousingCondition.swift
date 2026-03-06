import Foundation

/// Value Object que representa as condições de habitabilidade e infraestrutura de uma residência.
///
/// Consolida o mapeamento socioambiental da família, incluindo acesso a serviços básicos
/// e identificação de áreas de risco ou conflito social.
public struct HousingCondition: Codable, Equatable, Hashable, Sendable {

    // MARK: - Nested Types

    /// Classifica a natureza da posse ou ocupação do imóvel.
    public enum ConditionType: String, Codable, Sendable {
        case owned = "OWNED"
        case rented = "RENTED"
        case ceded = "CEDED"
        case squatted = "SQUATTED"
    }

    /// Identifica o material predominante na estrutura das paredes.
    public enum WallMaterial: String, Codable, Sendable {
        case masonry = "MASONRY"
        case finishedWood = "FINISHED_WOOD"
        case makeshiftMaterials = "MAKESHIFT_MATERIALS"
    }

    /// Define a principal forma de acesso à água potável.
    public enum WaterSupply: String, Codable, Sendable {
        case publicNetwork = "PUBLIC_NETWORK"
        case wellOrSpring = "WELL_OR_SPRING"
        case rainwaterHarvest = "RAINWATER_HARVEST"
        case waterTruck = "WATER_TRUCK"
        case other = "OTHER"
    }

    /// Classifica a regularidade e disponibilidade de energia elétrica.
    public enum ElectricityAccess: String, Codable, Sendable {
        case meteredConnection = "METERED_CONNECTION"
        case irregularConnection = "IRREGULAR_CONNECTION"
        case noAccess = "NO_ACCESS"
    }

    /// Define a forma de descarte de dejetos e saneamento.
    public enum SewageDisposal: String, Codable, Sendable {
        case publicSewer = "PUBLIC_SEWER"
        case septicTank = "SEPTIC_TANK"
        case rudimentaryPit = "RUDIMENTARY_PIT"
        case openSewage = "OPEN_SEWAGE"
        case noBathroom = "NO_BATHROOM"
    }

    /// Define a periodicidade e forma de coleta de resíduos sólidos.
    public enum WasteCollection: String, Codable, Sendable {
        case directCollection = "DIRECT_COLLECTION"
        case indirectCollection = "INDIRECT_COLLECTION"
        case noCollection = "NO_COLLECTION"
    }

    /// Avalia o grau de acessibilidade arquitetônica para pessoas com deficiência.
    public enum AccessibilityLevel: String, Codable, Sendable {
        case fullyAccessible = "FULLY_ACCESSIBLE"
        case partiallyAccessible = "PARTIALLY_ACCESSIBLE"
        case notAccessible = "NOT_ACCESSIBLE"
    }

    // MARK: - Properties

    public let type: ConditionType
    public let wallMaterial: WallMaterial
    public let numberOfRooms: Int
    public let numberOfBedrooms: Int
    public let numberOfBathrooms: Int
    public let waterSupply: WaterSupply
    public let hasPipedWater: Bool
    public let electricityAccess: ElectricityAccess
    public let sewageDisposal: SewageDisposal
    public let wasteCollection: WasteCollection
    public let accessibilityLevel: AccessibilityLevel
    public let isInGeographicRiskArea: Bool
    public let hasDifficultAccess: Bool
    public let isInSocialConflictArea: Bool
    public let hasDiagnosticObservations: Bool

    // MARK: - Initializer

    /// Inicializa uma condição de moradia validada.
    ///
    /// - Throws: `HousingConditionError` se números forem negativos ou inconsistentes.
    public init(
        type: ConditionType,
        wallMaterial: WallMaterial,
        numberOfRooms: Int,
        numberOfBedrooms: Int,
        numberOfBathrooms: Int,
        waterSupply: WaterSupply,
        hasPipedWater: Bool,
        electricityAccess: ElectricityAccess,
        sewageDisposal: SewageDisposal,
        wasteCollection: WasteCollection,
        accessibilityLevel: AccessibilityLevel,
        isInGeographicRiskArea: Bool,
        hasDifficultAccess: Bool,
        isInSocialConflictArea: Bool,
        hasDiagnosticObservations: Bool
    ) throws {
        guard numberOfRooms >= 0 else {
            throw HousingConditionError.negativeRooms
        }

        guard numberOfBedrooms >= 0 else {
            // Reaproveitando erro ou criando novo se necessário
            throw HousingConditionError.negativeRooms 
        }

        guard numberOfBathrooms >= 0 else {
            throw HousingConditionError.negativeBathrooms
        }

        guard numberOfBedrooms <= numberOfRooms else {
            throw HousingConditionError.bathroomsExceedRooms // TODO: Criar erro específico para bedrooms
        }

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
