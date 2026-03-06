import Foundation

extension UpdatePlacementHistoryCommandHandler {
    public func mapError(_ error: Error) -> UpdatePlacementHistoryError {
        if let e = error as? UpdatePlacementHistoryError { return e }
        
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
