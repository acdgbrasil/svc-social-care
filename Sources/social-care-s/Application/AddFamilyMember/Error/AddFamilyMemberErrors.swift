import Foundation

/// Erros específicos para o caso de uso de adição de membros familiares.
public enum AddFamilyMemberError: Error, Sendable, Equatable {
    case useCaseNotImplemented
    case repositoryNotAvailable
    case personIdAlreadyExists
    case invalidDiagnosisListFormat
    case invalidPersonIdFormat
    case persistenceMappingFailure(patientId: String? = nil, issues: [String] = [], issueCount: Int? = nil)
    case patientNotFound
}

extension AddFamilyMemberError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "APP"

    /// Converte o erro interno no formato padronizado AppError.
    public var asAppError: AppError {
        switch self {
        case .useCaseNotImplemented:
            return appFailure(
                "001",
                kind: "UseCaseNotImplemented",
                "O caso de uso não foi implementado.",
                category: .infrastructureDependencyFailure,
                severity: .critical,
                http: 500
            )
        case .repositoryNotAvailable:
            return appFailure(
                "002",
                kind: "RepositoryNotAvailable",
                "O repositório não está disponível no momento.",
                category: .infrastructureDependencyFailure,
                severity: .error,
                http: 503
            )
        case .personIdAlreadyExists:
            return appFailure(
                "003",
                kind: "PersonIdAlreadyExists",
                "O PersonId já existe.",
                category: .conflict,
                severity: .warning,
                http: 409
            )
        case .invalidDiagnosisListFormat:
            return appFailure(
                "004",
                kind: "InvalidDiagnosisListFormat",
                "Falha ao converter a lista de diagnósticos.",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 400
            )
        case .invalidPersonIdFormat:
            return appFailure(
                "005",
                kind: "InvalidPersonIdFormat",
                "O formato do ID de pessoa é inválido.",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 400
            )
        case .persistenceMappingFailure(let patientId, let issues, let issueCount):
            let resolvedIssueCount = issueCount ?? (issues.isEmpty ? nil : issues.count)
            let countLabel = resolvedIssueCount.map(String.init) ?? "?"
            var context: [String: Any] = [:]
            if let patientId {
                context["patientId"] = patientId
            }
            if !issues.isEmpty {
                context["issues"] = issues
            }
            if let resolvedIssueCount {
                context["issueCount"] = resolvedIssueCount
            }

            return appFailure(
                "006",
                kind: "PersistenceMappingFailure",
                "Falha ao mapear dados persistidos do paciente. (\(countLabel) erro(s))",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 500,
                context: context
            )
        case .patientNotFound:
           return appFailure(
                "007",
                kind: "PatientNotFound",
                "Não foi encontrado nenhum paciente com o ID fornecido.",
                category: .dataConsistencyIncident,
                severity: .error,
                http: 400
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
                tags: ["layer": "application", "use_case": "add_family_member"]
            ),
            http: http
        )
    }
}
