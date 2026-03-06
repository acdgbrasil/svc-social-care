import Foundation

/// Payload de entrada para o registro de um atendimento.
public struct RegisterAppointmentCommand: ResultCommand {
    public typealias Result = String
    
    public let patientId: String
    public let professionalId: String
    public let summary: String?
    public let actionPlan: String?
    public let type: String?
    public let date: Date?
    
    public init(
        patientId: String,
        professionalId: String,
        summary: String? = nil,
        actionPlan: String? = nil,
        type: String? = nil,
        date: Date? = nil
    ) {
        self.patientId = patientId
        self.professionalId = professionalId
        self.summary = summary
        self.actionPlan = actionPlan
        self.type = type
        self.date = date
    }
}
