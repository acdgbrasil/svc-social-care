import Foundation

extension UpdateHealthStatusCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateHealthStatusError {
        if let e = error as? UpdateHealthStatusError {
            return e
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
