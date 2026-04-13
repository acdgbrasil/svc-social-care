import Foundation

extension UpdatePlacementHistoryCommandHandler {
    public func mapError(_ error: Error) -> UpdatePlacementHistoryError {
        if let e = error as? UpdatePlacementHistoryError { return e }
        
        if let e = error as? PatientError {
            switch e {
            case .incompatiblePlacementSituation, .incompatibleGuardianshipSituation:
                return .incompatibleSeparationSituation
            case .patientIsWaitlisted:
                return .patientNotActive(reason: "o paciente está na lista de espera. Admita o paciente antes de realizar alterações.")
            case .patientIsDischarged:
                return .patientNotActive(reason: "o paciente está desligado. Readmita o paciente antes de realizar alterações.")
            default:
                return .persistenceMappingFailure(issues: [String(describing: e)])
            }
        }

        if let e = error as? PlacementError {
            switch e {
            case .invalidDateRange:
                return .invalidDateRange(memberId: "unknown")
            }
        }
        
        if let e = error as? PIDError {
            switch e {
            case .invalidFormat(let value):
                return .persistenceMappingFailure(issues: ["Invalid PID format: \(value)"])
            }
        }
        
        return .persistenceMappingFailure(issues: [String(describing: error)])
    }
}
