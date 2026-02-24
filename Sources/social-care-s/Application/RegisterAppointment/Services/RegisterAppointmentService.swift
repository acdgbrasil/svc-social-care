import Foundation

/// Implementação do serviço Maestro para registro de atendimentos.
struct RegisterAppointmentService: RegisterAppointmentUseCase {
    private let repository: any PatientRepository
    private let eventBus: any EventBus
    
    init(repository: any PatientRepository, eventBus: any EventBus) {
        self.repository = repository
        self.eventBus = eventBus
    }
    
    func execute(command: RegisterAppointmentCommand) async throws(RegisterAppointmentError) -> String {
        do {
            // 1. Parse
            let personId = try PersonId(command.patientId)
            let professionalId = try ProfessionalId(command.professionalId)
            let date = try command.date.map { try TimeStamp($0) } ?? TimeStamp.now
            
            let type: SocialCareAppointment.AppointmentType
            if let typeString = command.type {
                guard let resolvedType = SocialCareAppointment.AppointmentType(rawValue: typeString) else {
                    throw RegisterAppointmentError.invalidType(received: typeString, expected: SocialCareAppointment.AppointmentType.allCases.map { $0.rawValue }.joined(separator: ", "))
                }
                type = resolvedType
            } else {
                type = .other
            }
            
            // 2. Fetch
            guard var patient = try await repository.find(byPersonId: personId) else {
                throw RegisterAppointmentError.patientNotFound
            }
            
            // 3. Domain Logic
            let appointmentId = AppointmentId()
            try patient.addAppointment(
                id: appointmentId,
                date: date,
                professionalInChargeId: professionalId,
                type: type,
                summary: command.summary ?? "",
                actionPlan: command.actionPlan ?? "",
                now: .now
            )
            
            // 4. Persistence & Events
            try await repository.save(patient)
            try await eventBus.publish(patient.uncommittedEvents)
            
            return appointmentId.description
            
        } catch {
            throw mapError(error, patientId: command.patientId)
        }
    }
}
