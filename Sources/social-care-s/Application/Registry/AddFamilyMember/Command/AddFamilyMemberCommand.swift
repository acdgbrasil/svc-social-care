import Foundation

public struct AddFamilyMemberCommand: Command {
    public let patientId: String
    public let memberPersonId: String
    public let relationship: String
    public let isResiding: Bool
    public let isCaregiver: Bool
    public let hasDisability: Bool
    public let requiredDocuments: [String]
    public let birthDate: Date
    public let prRelationshipId: String
    public let actorId: String

    public init(
        patientId: String,
        memberPersonId: String,
        relationship: String,
        isResiding: Bool,
        isCaregiver: Bool,
        hasDisability: Bool,
        requiredDocuments: [String],
        birthDate: Date,
        prRelationshipId: String,
        actorId: String
    ) {
        self.patientId = patientId
        self.memberPersonId = memberPersonId
        self.relationship = relationship
        self.isResiding = isResiding
        self.isCaregiver = isCaregiver
        self.hasDisability = hasDisability
        self.requiredDocuments = requiredDocuments
        self.birthDate = birthDate
        self.prRelationshipId = prRelationshipId
        self.actorId = actorId
    }
}
