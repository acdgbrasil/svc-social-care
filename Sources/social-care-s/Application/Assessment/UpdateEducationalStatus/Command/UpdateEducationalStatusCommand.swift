import Foundation

public struct UpdateEducationalStatusCommand: Command {
    public struct ProfileDraft: Sendable {
        public let memberId: String
        public let canReadWrite: Bool
        public let attendsSchool: Bool
        public let educationLevelId: String

        public init(memberId: String, canReadWrite: Bool, attendsSchool: Bool, educationLevelId: String) {
            self.memberId = memberId
            self.canReadWrite = canReadWrite
            self.attendsSchool = attendsSchool
            self.educationLevelId = educationLevelId
        }
    }

    public struct OccurrenceDraft: Sendable {
        public let memberId: String
        public let date: Date
        public let effectId: String
        public let isSuspensionRequested: Bool

        public init(memberId: String, date: Date, effectId: String, isSuspensionRequested: Bool) {
            self.memberId = memberId
            self.date = date
            self.effectId = effectId
            self.isSuspensionRequested = isSuspensionRequested
        }
    }

    public let patientId: String
    public let memberProfiles: [ProfileDraft]
    public let programOccurrences: [OccurrenceDraft]

    public init(patientId: String, memberProfiles: [ProfileDraft], programOccurrences: [OccurrenceDraft]) {
        self.patientId = patientId
        self.memberProfiles = memberProfiles
        self.programOccurrences = programOccurrences
    }
}
