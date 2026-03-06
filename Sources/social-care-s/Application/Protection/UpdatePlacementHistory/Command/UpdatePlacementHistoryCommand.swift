import Foundation

public struct UpdatePlacementHistoryCommand: Command {
    public struct RegistryDraft: Sendable {
        public let memberId: String
        public let startDate: Date
        public let endDate: Date?
        public let reason: String

        public init(memberId: String, startDate: Date, endDate: Date?, reason: String) {
            self.memberId = memberId
            self.startDate = startDate
            self.endDate = endDate
            self.reason = reason
        }
    }

    public struct CollectiveDraft: Sendable {
        public let homeLossReport: String?
        public let thirdPartyGuardReport: String?

        public init(homeLossReport: String?, thirdPartyGuardReport: String?) {
            self.homeLossReport = homeLossReport
            self.thirdPartyGuardReport = thirdPartyGuardReport
        }
    }

    public struct SeparationDraft: Sendable {
        public let adultInPrison: Bool
        public let adolescentInInternment: Bool

        public init(adultInPrison: Bool, adolescentInInternment: Bool) {
            self.adultInPrison = adultInPrison
            self.adolescentInInternment = adolescentInInternment
        }
    }

    public let patientId: String
    public let registries: [RegistryDraft]
    public let collectiveSituations: CollectiveDraft
    public let separationChecklist: SeparationDraft

    public init(patientId: String, registries: [RegistryDraft], collectiveSituations: CollectiveDraft, separationChecklist: SeparationDraft) {
        self.patientId = patientId
        self.registries = registries
        self.collectiveSituations = collectiveSituations
        self.separationChecklist = separationChecklist
    }
}
