import Foundation

public struct RegisterIntakeInfoCommand: Command {
    public struct ProgramLinkDraft: Sendable {
        public let programId: String
        public let observation: String?

        public init(programId: String, observation: String?) {
            self.programId = programId
            self.observation = observation
        }
    }

    public let patientId: String
    public let ingressTypeId: String
    public let originName: String?
    public let originContact: String?
    public let serviceReason: String
    public let linkedSocialPrograms: [ProgramLinkDraft]

    public init(patientId: String, ingressTypeId: String, originName: String?, originContact: String?, serviceReason: String, linkedSocialPrograms: [ProgramLinkDraft]) {
        self.patientId = patientId
        self.ingressTypeId = ingressTypeId
        self.originName = originName
        self.originContact = originContact
        self.serviceReason = serviceReason
        self.linkedSocialPrograms = linkedSocialPrograms
    }
}
