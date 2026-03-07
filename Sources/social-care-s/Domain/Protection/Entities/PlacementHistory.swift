import Foundation

/// Entity that records the history of family separation and institutional placements.
public struct PlacementHistory: Codable, Equatable, Sendable {
    
    public let familyId: PatientId
    public let individualPlacements: [PlacementRegistry]
    public let collectiveSituations: CollectiveSituations
    public let separationChecklist: SeparationChecklist
    
    public init(
        familyId: PatientId,
        individualPlacements: [PlacementRegistry],
        collectiveSituations: CollectiveSituations,
        separationChecklist: SeparationChecklist
    ) {
        self.familyId = familyId
        self.individualPlacements = individualPlacements
        self.collectiveSituations = collectiveSituations
        self.separationChecklist = separationChecklist
    }
}

public struct PlacementRegistry: Codable, Equatable, Sendable {
    public let id: UUID
    public let memberId: PersonId
    public let startDate: TimeStamp
    public let endDate: TimeStamp?
    public let reason: String
    
    public init(id: UUID = UUID(), memberId: PersonId, startDate: TimeStamp, endDate: TimeStamp?, reason: String) throws {
        if let end = endDate {
            guard end >= startDate else {
                throw PlacementError.invalidDateRange
            }
        }
        self.id = id
        self.memberId = memberId
        self.startDate = startDate
        self.endDate = endDate
        self.reason = reason
    }
}

public struct CollectiveSituations: Codable, Equatable, Sendable {
    public let homeLossReport: String?
    public let thirdPartyGuardReport: String?

    public init(homeLossReport: String?, thirdPartyGuardReport: String?) {
        self.homeLossReport = homeLossReport
        self.thirdPartyGuardReport = thirdPartyGuardReport
    }
}

public struct SeparationChecklist: Codable, Equatable, Sendable {
    public let adultInPrison: Bool
    public let adolescentInInternment: Bool

    public init(adultInPrison: Bool, adolescentInInternment: Bool) {
        self.adultInPrison = adultInPrison
        self.adolescentInInternment = adolescentInInternment
    }
}

public enum PlacementError: Error, Sendable, Equatable {
    case invalidDateRange
}

extension PlacementError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/placement"
    private static let codePrefix = "PLC"

    public var asAppError: AppError {
        switch self {
        case .invalidDateRange:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A data de fim do acolhimento nao pode ser anterior a data de inicio.",
                bc: Self.bc, module: Self.module, kind: "InvalidDateRange",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["entity": "placement"]),
                http: 422
            )
        }
    }
}
