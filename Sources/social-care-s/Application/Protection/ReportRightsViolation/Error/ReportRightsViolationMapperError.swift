import Foundation

extension ReportRightsViolationCommandHandler {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    public func mapError(_ error: Error, patientId: String? = nil) -> ReportRightsViolationError {
        if let e = error as? ReportRightsViolationError {
            return e
        }
        
        if let e = error as? PatientError {
            switch e {
            case .violationTargetOutsideBoundary(let targetId):
                return .targetOutsideBoundary(targetId)
            case .patientIsWaitlisted:
                return .patientNotActive(reason: "o paciente está na lista de espera. Admita o paciente antes de realizar alterações.")
            case .patientIsDischarged:
                return .patientNotActive(reason: "o paciente está desligado. Readmita o paciente antes de realizar alterações.")
            default:
                break
            }
        }

        if let e = error as? RightsViolationReportError {
            switch e {
            case .reportDateInFuture:
                return .reportDateInFuture
            case .incidentAfterReport:
                return .incidentAfterReport
            case .emptyDescription:
                return .emptyDescription
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
        
        if let e = error as? ViolationReportIdError {
            switch e {
            case .invalidFormat(let value):
                return .invalidViolationReportIdFormat(value)
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
