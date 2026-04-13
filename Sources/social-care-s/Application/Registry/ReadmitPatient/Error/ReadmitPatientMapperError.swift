import Foundation

extension ReadmitPatientCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String) -> ReadmitPatientError {
        if let e = error as? ReadmitPatientError {
            return e
        }

        if let e = error as? PatientError {
            switch e {
            case .alreadyActive:
                return .alreadyActive(patientId)
            default:
                return .patientNotFound(patientId)
            }
        }

        if let e = error as? DischargeInfoError {
            switch e {
            case .notesExceedMaxLength(let length):
                return .notesExceedMaxLength(length)
            case .notesRequiredWhenReasonIsOther:
                // Unreachable in readmit flow — readmit never creates DischargeInfo.
                // Mapped defensively to avoid compiler warning on exhaustive switch.
                return .alreadyActive(patientId)
            }
        }

        if error is PatientIdError {
            return .invalidPatientIdFormat(patientId)
        }

        return .patientNotFound(patientId)
    }
}
