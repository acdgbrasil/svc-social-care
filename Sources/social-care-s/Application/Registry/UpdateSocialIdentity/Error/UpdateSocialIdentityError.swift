import Foundation

/// Erros específicos para o caso de uso de atualização de identidade social.
public enum UpdateSocialIdentityError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case indigenousInVillageMissingDescription
    case indigenousOutsideVillageMissingDescription
    case descriptionRequiredForOtherType
    case invalidLookupId(table: String, id: String)
    case persistenceMappingFailure(issues: [String])
    case patientNotActive(reason: String)
}

extension UpdateSocialIdentityError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "USIA"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", category: .dataConsistencyIncident, severity: .error, http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .indigenousInVillageMissingDescription:
            return appFailure("003", kind: "IndigenousInVillageMissingDescription", "Família indígena residente em aldeia requer descrição da aldeia.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .indigenousOutsideVillageMissingDescription:
            return appFailure("004", kind: "IndigenousOutsideVillageMissingDescription", "Família indígena fora de aldeia requer descrição complementar.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .descriptionRequiredForOtherType:
            return appFailure("006", kind: "DescriptionRequiredForOtherType", "Descrição detalhada é obrigatória para este tipo de identidade social.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .invalidLookupId(let table, let id):
            return appFailure("007", kind: "InvalidLookupId", "ID '\(id)' nao encontrado na tabela '\(table)'.", category: .domainRuleViolation, severity: .warning, http: 422)
        case .patientNotActive(let reason):
            return appFailure("008", kind: "PatientNotActive", "Operação não permitida: \(reason)", category: .conflict, severity: .warning, http: 409)
        case .persistenceMappingFailure(let issues):
            return appFailure("005", kind: "PersistenceMappingFailure", "Falha de infraestrutura ao salvar a identidade social.", category: .infrastructureDependencyFailure, severity: .critical, http: 500, context: ["issues": issues])
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_social_identity"]),
            http: http
        )
    }
}
