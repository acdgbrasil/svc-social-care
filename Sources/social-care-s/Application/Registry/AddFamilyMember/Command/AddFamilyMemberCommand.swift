import Foundation

public struct AddFamilyMemberCommand: Command {
    public let patientPersonId: String
    public let memberPersonId: String
    public let relationship: String
    public let isResiding: Bool
    public let isCaregiver: Bool
    public let hasDisability: Bool
    public let requiredDocuments: [String]
    public let birthDate: Date

    public init(
        patientPersonId: String,
        memberPersonId: String,
        relationship: String,
        isResiding: Bool,
        isCaregiver: Bool,
        hasDisability: Bool,
        requiredDocuments: [String],
        birthDate: Date
    ) {
        self.patientPersonId = patientPersonId
        self.memberPersonId = memberPersonId
        self.relationship = relationship
        self.isResiding = isResiding
        self.isCaregiver = isCaregiver
        self.hasDisability = hasDisability
        self.requiredDocuments = requiredDocuments
        self.birthDate = birthDate
    }
}
