import Foundation

/// Erros específicos para o caso de uso de registro de atendimento.
enum RegisterAppointmentError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidProfessionalIdFormat(String)
    case invalidDateFormat
    case invalidType(received: String, expected: String)
    case missingNarrative
    case summaryTooLong(limit: Int)
    case actionPlanTooLong(limit: Int)
    case dateInFuture
    case persistenceMappingFailure(issues: [String])
}

extension RegisterAppointmentError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "REGA"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidProfessionalIdFormat(let value):
            return appFailure("003", kind: "InvalidProfessionalIdFormat", "ID de profissional inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidDateFormat:
            return appFailure("004", kind: "InvalidDateFormat", "Data inválida fornecida.", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidType(let received, let expected):
            return appFailure("005", kind: "InvalidType", "Tipo de atendimento inválido: \(received). Esperado: \(expected).", category: .domainRuleViolation, severity: .error, http: 400)
        case .missingNarrative:
            return appFailure("006", kind: "MissingNarrative", "O atendimento deve possuir ao menos um resumo ou um plano de ação.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .summaryTooLong(let limit):
            return appFailure("007", kind: "SummaryTooLong", "O resumo excede o limite de \(limit) caracteres.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .actionPlanTooLong(let limit):
            return appFailure("008", kind: "ActionPlanTooLong", "O plano de ação excede o limite de \(limit) caracteres.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .dateInFuture:
            return appFailure("009", kind: "DateInFuture", "A data do atendimento não pode estar no futuro.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("010", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar o atendimento.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "register_appointment"]),
            http: http
        )
    }
}
