import Foundation

public enum UpdateSocialHealthSummaryError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case functionalDependenciesEmpty
    case unexpectedFailure(String)
    case patientNotActive(reason: String)
}

extension UpdateSocialHealthSummaryError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "USHS"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", http: 400)
        case .functionalDependenciesEmpty:
            return appFailure("003", kind: "FunctionalDependenciesEmpty", "A lista de dependências funcionais contém itens vazios.", http: 422)
        case .patientNotActive(let reason):
            let message = reason == "PATIENT_IS_WAITLISTED"
                ? "Operação não permitida: o paciente está na lista de espera. Admita o paciente antes de realizar alterações."
                : "Operação não permitida: o paciente está desligado. Readmita o paciente antes de realizar alterações."
            return appFailure("004", kind: "PatientNotActive", message, http: 409)
        case .unexpectedFailure(let detail):
            return appFailure("999", kind: "UnexpectedFailure", "Falha inesperada: \(detail)", http: 500)
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, http: Int) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: [:], safeContext: [:],
            observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_social_health_summary"]),
            http: http
        )
    }
}
