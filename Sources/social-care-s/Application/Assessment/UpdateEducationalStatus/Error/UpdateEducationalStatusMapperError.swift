import Foundation

extension UpdateEducationalStatusCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateEducationalStatusError {
        if let e = error as? UpdateEducationalStatusError {
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
