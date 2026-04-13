import Foundation

/// Erros especificos para o caso de uso de admissao de paciente.
public enum AdmitPatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyActive(String)
    case cannotAdmitDischarged(String)
    case invalidPatientIdFormat(String)
}

extension AdmitPatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "ADM"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound(let id):
            return appFailure("001", kind: "PatientNotFound", "Paciente nao encontrado: \(id).", category: .domainRuleViolation, severity: .warning, http: 404)
        case .alreadyActive(let id):
            return appFailure("002", kind: "AlreadyActive", "O paciente \(id) ja esta ativo.", category: .conflict, severity: .warning, http: 409)
        case .cannotAdmitDischarged(let id):
            return appFailure("003", kind: "CannotAdmitDischarged", "Paciente desligado \(id) nao pode ser admitido.", category: .conflict, severity: .warning, http: 409)
        case .invalidPatientIdFormat(let value):
            return appFailure("004", kind: "InvalidPatientIdFormat", "Formato de ID do paciente invalido: '\(value)'.", category: .dataConsistencyIncident, severity: .error, http: 400)
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "admit_patient"]),
            http: http
        )
    }
}
