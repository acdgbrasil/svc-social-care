import Foundation

extension UpdateWorkAndIncomeCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateWorkAndIncomeError {
        if let e = error as? UpdateWorkAndIncomeError {
            return e
        }

        if let e = error as? PatientError {
            switch e {
            case .patientIsWaitlisted:
                return .patientNotActive(reason: "o paciente está na lista de espera. Admita o paciente antes de realizar alterações.")
            case .patientIsDischarged:
                return .patientNotActive(reason: "o paciente está desligado. Readmita o paciente antes de realizar alterações.")
            default:
                break
            }
        }

        if let e = error as? PatientIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
            }
        }

        if let e = error as? PIDError {
            switch e {
            case .invalidFormat(let value):
                return .invalidPersonIdFormat(value)
            }
        }

        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
