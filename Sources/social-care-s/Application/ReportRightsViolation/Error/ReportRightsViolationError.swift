import Foundation

/// Erros específicos para o caso de uso de relato de violação de direitos.
enum ReportRightsViolationError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidViolationReportIdFormat(String)
    case invalidViolationType(String)
    case reportDateInFuture
    case incidentAfterReport
    case emptyDescription
    case targetOutsideBoundary(String)
    case persistenceMappingFailure(issues: [String])
}

extension ReportRightsViolationError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "RRV"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidViolationReportIdFormat(let value):
            return appFailure("003", kind: "InvalidViolationReportIdFormat", "ID de relatório de violação inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidViolationType(let value):
            return appFailure("004", kind: "InvalidViolationType", "Tipo de violação inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .reportDateInFuture:
            return appFailure("005", kind: "ReportDateInFuture", "A data do relatório não pode estar no futuro.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .incidentAfterReport:
            return appFailure("006", kind: "IncidentAfterReport", "A data do incidente não pode ser posterior à data do relatório.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .emptyDescription:
            return appFailure("007", kind: "EmptyDescription", "A descrição dos fatos não pode ser vazia.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .targetOutsideBoundary(let targetId):
            return appFailure("008", kind: "TargetOutsideBoundary", "A vítima da violação (\(targetId)) não pertence a este paciente ou sua família.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("009", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar o relato de violação.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "report_rights_violation"]),
            http: http
        )
    }
}
