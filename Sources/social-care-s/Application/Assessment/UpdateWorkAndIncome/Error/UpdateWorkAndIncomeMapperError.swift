import Foundation

extension UpdateWorkAndIncomeCommandHandler {
    public func mapError(_ error: Error, patientId: String? = nil) -> UpdateWorkAndIncomeError {
        if let e = error as? UpdateWorkAndIncomeError {
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
