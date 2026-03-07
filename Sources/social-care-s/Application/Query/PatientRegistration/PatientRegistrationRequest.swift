import Foundation

/// Payload completo recebido pelo Query Orchestrator para o cadastro da pessoa de referência.
public struct PatientRegistrationRequest: Sendable {

    public struct FamilyMemberDraft: Sendable {
        public let memberPersonId: String
        public let relationship: String
        public let isResiding: Bool
        public let isCaregiver: Bool
        public let hasDisability: Bool
        public let requiredDocuments: [String]
        public let birthDate: Date
        
        public init(memberPersonId: String, relationship: String, isResiding: Bool, isCaregiver: Bool, hasDisability: Bool, requiredDocuments: [String], birthDate: Date) {
            self.memberPersonId = memberPersonId
            self.relationship = relationship
            self.isResiding = isResiding
            self.isCaregiver = isCaregiver
            self.hasDisability = hasDisability
            self.requiredDocuments = requiredDocuments
            self.birthDate = birthDate
        }
    }

    public let personId: String
    public let initialDiagnoses: [RegisterPatientCommand.DiagnosisDraft]
    public let personalData: RegisterPatientCommand.PersonalDataDraft?
    public let civilDocuments: RegisterPatientCommand.CivilDocumentsDraft?
    public let address: RegisterPatientCommand.AddressDraft?
    public let familyMembers: [FamilyMemberDraft]
    public let socialIdentity: RegisterPatientCommand.SocialIdentityDraft?
    public let prRelationshipId: String
    public let actorId: String

    public init(
        personId: String,
        initialDiagnoses: [RegisterPatientCommand.DiagnosisDraft],
        personalData: RegisterPatientCommand.PersonalDataDraft? = nil,
        civilDocuments: RegisterPatientCommand.CivilDocumentsDraft? = nil,
        address: RegisterPatientCommand.AddressDraft? = nil,
        familyMembers: [FamilyMemberDraft] = [],
        socialIdentity: RegisterPatientCommand.SocialIdentityDraft? = nil,
        prRelationshipId: String,
        actorId: String
    ) {
        self.personId = personId
        self.initialDiagnoses = initialDiagnoses
        self.personalData = personalData
        self.civilDocuments = civilDocuments
        self.address = address
        self.familyMembers = familyMembers
        self.socialIdentity = socialIdentity
        self.prRelationshipId = prRelationshipId
        self.actorId = actorId
    }
}
