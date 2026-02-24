import Foundation

extension ReportRightsViolationService {
    /// Mapeia erros genéricos ou de domínio para o erro específico do Caso de Uso.
    func mapError(_ error: Error, patientId: String? = nil) -> ReportRightsViolationError {
        if let e = error as? ReportRightsViolationError {
            return e
        }
        
        if let e = error as? PatientError {
            switch e {
            case .violationTargetOutsideBoundary(let targetId):
                return .targetOutsideBoundary(targetId)
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
