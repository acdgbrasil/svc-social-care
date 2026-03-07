import Foundation

public struct UpdateCommunitySupportNetworkCommand: Command {
    public let patientId: String
    public let hasRelativeSupport: Bool
    public let hasNeighborSupport: Bool
    public let familyConflicts: String
    public let patientParticipatesInGroups: Bool
    public let familyParticipatesInGroups: Bool
    public let patientHasAccessToLeisure: Bool
    public let facesDiscrimination: Bool
    public let actorId: String

    public init(
        patientId: String,
        hasRelativeSupport: Bool,
        hasNeighborSupport: Bool,
        familyConflicts: String,
        patientParticipatesInGroups: Bool,
        familyParticipatesInGroups: Bool,
        patientHasAccessToLeisure: Bool,
        facesDiscrimination: Bool,
        actorId: String
    ) {
        self.patientId = patientId
        self.hasRelativeSupport = hasRelativeSupport
        self.hasNeighborSupport = hasNeighborSupport
        self.familyConflicts = familyConflicts
        self.patientParticipatesInGroups = patientParticipatesInGroups
        self.familyParticipatesInGroups = familyParticipatesInGroups
        self.patientHasAccessToLeisure = patientHasAccessToLeisure
        self.facesDiscrimination = facesDiscrimination
        self.actorId = actorId
    }
}
