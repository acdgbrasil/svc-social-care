import Foundation

public enum UpdateEducationalStatusError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidLookupId(table: String, id: String)
    case persistenceMappingFailure(issues: [String])
    case patientNotActive(reason: String)
}

extension UpdateEducationalStatusError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "UES"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente nao foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa invalido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidLookupId(let table, let id):
            return appFailure("003", kind: "InvalidLookupId", "ID '\(id)' nao encontrado na tabela '\(table)'.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .patientNotActive(let reason):
            let message = reason == "PATIENT_IS_WAITLISTED"
                ? "Operação não permitida: o paciente está na lista de espera. Admita o paciente antes de realizar alterações."
                : "Operação não permitida: o paciente está desligado. Readmita o paciente antes de realizar alterações."
            return appFailure("005", kind: "PatientNotActive", message, category: .conflict, severity: .warning, http: 409, context: ["reason": reason])
        case .persistenceMappingFailure(let issues):
            return appFailure("004", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar status educacional.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_educational_status"]),
            http: http
        )
    }
}
