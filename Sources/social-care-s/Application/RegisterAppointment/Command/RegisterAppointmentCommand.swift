import Foundation

/// Payload de entrada para o registro de um atendimento.
struct RegisterAppointmentCommand: Sendable {
    let patientId: String
    let professionalId: String
    let summary: String?
    let actionPlan: String?
    let type: String?
    let date: Date?
    
    init(
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
