import Foundation

/// Payload de entrada para o relato de violação de direitos.
public struct ReportRightsViolationCommand: ResultCommand {
    public typealias Result = String
    
    public let patientId: String
    public let victimId: String
    public let violationType: String
    public let reportDate: Date?
    public let incidentDate: Date?
    public let descriptionOfFact: String
    public let actionsTaken: String?
    public let id: String?
    
    public init(
        patientId: String,
        victimId: String,
        violationType: String,
        reportDate: Date? = nil,
        incidentDate: Date? = nil,
        descriptionOfFact: String,
        actionsTaken: String? = nil,
        id: String? = nil
    ) {
        self.patientId = patientId
        self.victimId = victimId
        self.violationType = violationType
        self.reportDate = reportDate
        self.incidentDate = incidentDate
        self.descriptionOfFact = descriptionOfFact
        self.actionsTaken = actionsTaken
        self.id = id
    }
}
