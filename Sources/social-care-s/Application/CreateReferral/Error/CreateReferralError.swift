import Foundation

/// Erros específicos para o caso de uso de criação de encaminhamento.
enum CreateReferralError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case invalidProfessionalIdFormat(String)
    case invalidReferralIdFormat(String)
    case invalidDateFormat
    case invalidDestinationService(String)
    case targetOutsideBoundary(String)
    case dateInFuture
    case reasonMissing
    case persistenceMappingFailure(issues: [String])
}

extension CreateReferralError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "CREF"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidProfessionalIdFormat(let value):
            return appFailure("003", kind: "InvalidProfessionalIdFormat", "ID de profissional inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidReferralIdFormat(let value):
            return appFailure("004", kind: "InvalidReferralIdFormat", "ID de encaminhamento inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidDateFormat:
            return appFailure("005", kind: "InvalidDateFormat", "Data inválida fornecida.", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .invalidDestinationService(let value):
            return appFailure("006", kind: "InvalidDestinationService", "Serviço de destino inválido: \(value)", category: .domainRuleViolation, severity: .error, http: 400)
        case .targetOutsideBoundary(let targetId):
            return appFailure("007", kind: "TargetOutsideBoundary", "A pessoa encaminhada (\(targetId)) não pertence a este paciente ou sua família.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .dateInFuture:
            return appFailure("008", kind: "DateInFuture", "A data do encaminhamento não pode estar no futuro.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .reasonMissing:
            return appFailure("009", kind: "ReasonMissing", "O motivo do encaminhamento é obrigatório.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .persistenceMappingFailure(let issues):
            return appFailure("010", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar o encaminhamento.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "create_referral"]),
            http: http
        )
    }
}
