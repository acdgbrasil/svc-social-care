import Foundation

public enum RegisterIntakeInfoError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidLookupId(table: String, id: String)
    case persistenceMappingFailure(issues: [String])
}

extension RegisterIntakeInfoError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "RII"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "Patient not found.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "Invalid person ID format: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidLookupId(let table, let id):
            return appFailure("003", kind: "InvalidLookupId", "Lookup ID '\(id)' not found in table '\(table)'.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("004", kind: "PersistenceMappingFailure", "Infrastructure failure while saving intake information.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "register_intake"]),
            http: http
        )
    }
}
