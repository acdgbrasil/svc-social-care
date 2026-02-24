import Foundation

/// Erros específicos para o caso de uso de registro de paciente.
enum RegisterPatientError: Error, Sendable, Equatable {
    case personIdAlreadyExists
    case invalidPersonIdFormat(String)
    case invalidIcdCode(String)
    case invalidDiagnosisDate(date: String, now: String)
    case emptyDiagnosisDescription
    case initialDiagnosesRequired
    case repositoryNotAvailable
    case persistenceMappingFailure(issues: [String])
}

extension RegisterPatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "REGP"

    public var asAppError: AppError {
        switch self {
        case .personIdAlreadyExists:
            return appFailure("001", kind: "PersonIdAlreadyExists", "O paciente com este PersonId já está registrado.", category: .conflict, severity: .warning, http: 409)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidIcdCode(let value):
            return appFailure("003", kind: "InvalidIcdCode", "Código CID inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .invalidDiagnosisDate(let date, let now):
            return appFailure("004", kind: "InvalidDiagnosisDate", "Data do diagnóstico (\(date)) não pode ser futura (\(now)).", category: .domainRuleViolation, severity: .warning, http: 422)
        case .emptyDiagnosisDescription:
            return appFailure("005", kind: "EmptyDiagnosisDescription", "A descrição do diagnóstico é obrigatória.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .initialDiagnosesRequired:
            return appFailure("006", kind: "InitialDiagnosesRequired", "Ao menos um diagnóstico inicial deve ser informado.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .repositoryNotAvailable:
            return appFailure("007", kind: "RepositoryNotAvailable", "O repositório não está disponível.", category: .infrastructureDependencyFailure, severity: .critical, http: 503)
        case .persistenceMappingFailure(let issues):
            return appFailure("008", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar o paciente.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "register_patient"]),
            http: http
        )
    }
}
