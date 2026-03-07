import Foundation

public struct UpdateHealthStatusCommand: Command {
    public struct DeficiencyDraft: Sendable {
        public let memberId: String
        public let deficiencyTypeId: String
        public let needsConstantCare: Bool
        public let responsibleCaregiverName: String?

        public init(memberId: String, deficiencyTypeId: String, needsConstantCare: Bool, responsibleCaregiverName: String?) {
            self.memberId = memberId
            self.deficiencyTypeId = deficiencyTypeId
            self.needsConstantCare = needsConstantCare
            self.responsibleCaregiverName = responsibleCaregiverName
        }
    }

    public struct PregnantDraft: Sendable {
        public let memberId: String
        public let monthsGestation: Int
        public let startedPrenatalCare: Bool

        public init(memberId: String, monthsGestation: Int, startedPrenatalCare: Bool) {
            self.memberId = memberId
            self.monthsGestation = monthsGestation
            self.startedPrenatalCare = startedPrenatalCare
        }
    }

    public let patientId: String
    public let deficiencies: [DeficiencyDraft]
    public let gestatingMembers: [PregnantDraft]
    public let constantCareNeeds: [String]
    public let foodInsecurity: Bool
    public let actorId: String

    public init(patientId: String, deficiencies: [DeficiencyDraft], gestatingMembers: [PregnantDraft], constantCareNeeds: [String], foodInsecurity: Bool, actorId: String) {
        self.patientId = patientId
        self.deficiencies = deficiencies
        self.gestatingMembers = gestatingMembers
        self.constantCareNeeds = constantCareNeeds
        self.foodInsecurity = foodInsecurity
        self.actorId = actorId
    }
}
