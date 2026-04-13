import Foundation

/// Erros específicos para o caso de uso de atribuição de cuidador principal.
public enum AssignPrimaryCaregiverError: Error, Sendable, Equatable {
    case patientNotFound
    case familyMemberNotFound(personId: String)
    case invalidPersonIdFormat(String)
    case persistenceMappingFailure(issues: [String])
    case patientNotActive(reason: String)
}

extension AssignPrimaryCaregiverError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "APC"

    /// Converte o erro interno no formato padronizado AppError.
    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure(
                "001",
                kind: "PatientNotFound",
                "O paciente não foi encontrado.",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 404
            )
        case .familyMemberNotFound(let personId):
            return appFailure(
                "002",
                kind: "FamilyMemberNotFound",
                "O membro da família com ID \(personId) não foi encontrado.",
                category: .domainRuleViolation,
                severity: .warning,
                http: 404,
                context: ["personId": personId]
            )
        case .invalidPersonIdFormat(let value):
            return appFailure(
                "003",
                kind: "InvalidPersonIdFormat",
                "O formato do ID de pessoa é inválido: \(value).",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 400,
                context: ["value": value]
            )
        case .patientNotActive(let reason):
            return appFailure(
                "005",
                kind: "PatientNotActive",
                "Operação não permitida: \(reason)",
                category: .conflict,
                severity: .warning,
                http: 409
            )
        case .persistenceMappingFailure(let issues):
            return appFailure(
                "004",
                kind: "PersistenceMappingFailure",
                "Falha ao mapear dados de persistência.",
                category: .infrastructureDependencyFailure,
                severity: .critical,
                http: 500,
                context: ["issues": issues]
            )
        }
    }

    private func appFailure(
        _ subCode: String,
        kind: String,
        _ message: String,
        category: AppError.Category,
        severity: AppError.Severity,
        http: Int,
        context: [String: Any] = [:]
    ) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc,
            module: Self.module,
            kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(
                category: category,
                severity: severity,
                fingerprint: ["\(Self.codePrefix)-\(subCode)", Self.module],
                tags: ["layer": "application", "use_case": "assign_primary_caregiver"]
            ),
            http: http
        )
    }
}
