import Foundation

extension RegisterIntakeInfoCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> RegisterIntakeInfoError {
        if let e = error as? RegisterIntakeInfoError {
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
