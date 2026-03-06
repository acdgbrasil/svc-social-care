import Foundation

public enum UpdateHealthStatusError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidLookupId(table: String, id: String)
    case persistenceMappingFailure(issues: [String])
}

extension UpdateHealthStatusError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "UHS"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente nao foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa invalido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidLookupId(let table, let id):
            return appFailure("003", kind: "InvalidLookupId", "ID '\(id)' nao encontrado na tabela '\(table)'.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("004", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar status de saude.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_health_status"]),
            http: http
        )
    }
}
