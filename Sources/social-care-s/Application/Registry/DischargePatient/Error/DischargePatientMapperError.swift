import Foundation

extension DischargePatientCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String) -> DischargePatientError {
        if let e = error as? DischargePatientError {
            return e
        }

        if let e = error as? PatientError {
            switch e {
            case .alreadyDischarged:
                return .alreadyDischarged(patientId)
            default:
                return .patientNotFound(patientId)
            }
        }

        if let e = error as? DischargeInfoError {
            switch e {
            case .notesRequiredWhenReasonIsOther:
                return .notesRequiredForOtherReason
            case .notesExceedMaxLength(let length):
                return .notesExceedMaxLength(length)
            }
        }

        if error is PatientIdError {
            return .invalidPatientIdFormat(patientId)
        }

        return .patientNotFound(patientId)
    }
}
