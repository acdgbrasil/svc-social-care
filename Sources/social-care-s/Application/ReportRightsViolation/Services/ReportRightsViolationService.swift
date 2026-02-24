import Foundation

/// Implementação do serviço Maestro para relato de violação de direitos.
struct ReportRightsViolationService: ReportRightsViolationUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: ReportRightsViolationCommand) async throws(ReportRightsViolationError) -> String {
        do {
            // 1. Parse
            let patientPersonId = try PersonId(command.patientId)
            let victimId = try PersonId(command.victimId)
            let violationReportId = try command.id.map { try ViolationReportId($0) } ?? ViolationReportId()
            let reportDate = try command.reportDate.map { try TimeStamp($0) } ?? TimeStamp.now
            let incidentDate = try command.incidentDate.map { try TimeStamp($0) }
            
            guard let violationType = RightsViolationReport.ViolationType(rawValue: command.violationType) else {
                throw ReportRightsViolationError.invalidViolationType(command.violationType)
            }
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: patientPersonId) else {
                throw ReportRightsViolationError.patientNotFound
            }
            
            // 3. Domain Logic
            try patient.addRightsViolationReport(
                id: violationReportId,
                reportDate: reportDate,
                incidentDate: incidentDate,
                victimId: victimId,
                violationType: violationType,
                descriptionOfFact: command.descriptionOfFact,
                actionsTaken: command.actionsTaken ?? "",
                now: .now
            )
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
            return violationReportId.description
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
