import Foundation

extension WithdrawFromWaitlistCommandHandler {
    /// Mapeia erros genericos ou de dominio para o erro especifico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String) -> WithdrawFromWaitlistError {
        if let e = error as? WithdrawFromWaitlistError {
            return e
        }

        if let e = error as? PatientError {
            switch e {
            case .alreadyDischarged:
                return .alreadyDischarged(patientId)
            case .alreadyActive:
                return .patientIsActive(patientId)
            default:
                return .patientNotFound(patientId)
            }
        }

        if let e = error as? WithdrawInfoError {
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
