import Foundation

extension RegisterAppointmentService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> RegisterAppointmentError {
        if let e = error as? RegisterAppointmentError {
            return e
        }
        
        if let e = error as? SocialCareAppointmentError {
            switch e {
            case .dateInFuture:
                return .dateInFuture
            case .invalidType(let received, let expected):
                return .invalidType(received: received, expected: expected)
            case .missingNarrative:
                return .missingNarrative
            case .summaryTooLong(let limit):
                return .summaryTooLong(limit: limit)
            case .actionPlanTooLong(let limit):
                return .actionPlanTooLong(limit: limit)
            }
        }
        
        if let e = error as? PIDError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
            }
        }
        
        if let e = error as? ProfessionalIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidProfessionalIdFormat(value)
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
