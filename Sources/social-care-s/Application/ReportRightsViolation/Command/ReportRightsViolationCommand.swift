import Foundation

/// Payload de entrada para o relato de violação de direitos.
struct ReportRightsViolationCommand: Sendable {
    let patientId: String
    let victimId: String
    let violationType: String
    let reportDate: Date?
    let incidentDate: Date?
    let descriptionOfFact: String
    let actionsTaken: String?
    let id: String?
    
    init(
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
