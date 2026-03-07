import Foundation

public struct UpdateSocialHealthSummaryCommand: Command {
    public let patientId: String
    public let requiresConstantCare: Bool
    public let hasMobilityImpairment: Bool
    public let functionalDependencies: [String]
    public let hasRelevantDrugTherapy: Bool
    public let actorId: String

    public init(
        patientId: String,
        requiresConstantCare: Bool,
        hasMobilityImpairment: Bool,
        functionalDependencies: [String],
        hasRelevantDrugTherapy: Bool,
        actorId: String
    ) {
        self.patientId = patientId
        self.requiresConstantCare = requiresConstantCare
        self.hasMobilityImpairment = hasMobilityImpairment
        self.functionalDependencies = functionalDependencies
        self.hasRelevantDrugTherapy = hasRelevantDrugTherapy
        self.actorId = actorId
    }
}
