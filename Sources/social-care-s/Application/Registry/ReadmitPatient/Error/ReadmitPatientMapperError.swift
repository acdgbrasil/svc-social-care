import Foundation

extension ReadmitPatientCommandHandler {
    /// Mapeia erros de domínio para o erro específico do Caso de Uso.
    /// Erros não reconhecidos são propagados sem mascaramento.
    public func mapError(_ error: Error, patientId: String) -> any Error {
        if error is ReadmitPatientError { return error }

        if let e = error as? PatientError {
            switch e {
            case .alreadyActive:
                return ReadmitPatientError.alreadyActive(patientId)
            case .cannotReadmitWaitlisted:
                return ReadmitPatientError.alreadyActive(patientId)
            default:
                return error
            }
        }

        if let e = error as? DischargeInfoError {
            switch e {
            case .notesExceedMaxLength(let length):
                return ReadmitPatientError.notesExceedMaxLength(length)
            case .notesRequiredWhenReasonIsOther:
                return error
            }
        }

        if error is PatientIdError {
            return ReadmitPatientError.invalidPatientIdFormat(patientId)
        }

        return error
    }
}
