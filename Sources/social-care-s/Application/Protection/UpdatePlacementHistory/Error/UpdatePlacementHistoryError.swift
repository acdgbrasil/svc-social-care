import Foundation

public enum UpdatePlacementHistoryError: Error, Sendable, Equatable {
    case patientNotFound
    case memberNotFound(String)
    case invalidDateFormat
    case invalidDateRange(memberId: String)
    case incompatibleSeparationSituation
    case persistenceMappingFailure(issues: [String])
    case patientNotActive(reason: String)
}

extension UpdatePlacementHistoryError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "UPH"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "Patient not found.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .memberNotFound(let id):
            return appFailure("002", kind: "MemberNotFound", "Family member not found: \(id)", category: .domainRuleViolation, severity: .warning, http: 422)
        case .invalidDateFormat:
            return appFailure("003", kind: "InvalidDateFormat", "Invalid date format.", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidDateRange(let id):
            return appFailure("004", kind: "InvalidDateRange", "End date cannot be before start date for member: \(id)", category: .domainRuleViolation, severity: .error, http: 422)
        case .incompatibleSeparationSituation:
            return appFailure("005", kind: "IncompatibleSeparation", "The separation situation is incompatible with the family age composition.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .patientNotActive(let reason):
            let message = reason == "PATIENT_IS_WAITLISTED"
                ? "Operation not allowed: patient is waitlisted. Admit the patient before making changes."
                : "Operation not allowed: patient is discharged. Readmit the patient before making changes."
            return appFailure("007", kind: "PatientNotActive", message, category: .conflict, severity: .warning, http: 409, context: ["reason": reason])
        case .persistenceMappingFailure(let issues):
            return appFailure("006", kind: "PersistenceMappingFailure", "Infrastructure failure while saving placement history.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_placement"]),
            http: http
        )
    }
}
