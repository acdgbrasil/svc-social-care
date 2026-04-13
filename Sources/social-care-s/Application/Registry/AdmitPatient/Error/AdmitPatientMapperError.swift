import Foundation

extension AdmitPatientCommandHandler {
    /// Mapeia erros genericos ou de dominio para o erro especifico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String) -> AdmitPatientError {
        if let e = error as? AdmitPatientError {
            return e
        }

        if let e = error as? PatientError {
            switch e {
            case .alreadyActive:
                return .alreadyActive(patientId)
            case .cannotAdmitDischarged:
                return .cannotAdmitDischarged(patientId)
            default:
                return .patientNotFound(patientId)
            }
        }

        if error is PatientIdError {
            return .invalidPatientIdFormat(patientId)
        }

        return .patientNotFound(patientId)
    }
}
