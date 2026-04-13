import Foundation

/// Erros especificos para o caso de uso de retirada de paciente da fila de espera.
public enum WithdrawFromWaitlistError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyDischarged(String)
    case patientIsActive(String)
    case invalidReason(String)
    case notesRequiredForOtherReason
    case notesExceedMaxLength(Int)
    case invalidPatientIdFormat(String)
}

extension WithdrawFromWaitlistError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "WDR"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound(let id):
            return appFailure("001", kind: "PatientNotFound", "Paciente nao encontrado: \(id).", category: .domainRuleViolation, severity: .warning, http: 404)
        case .alreadyDischarged(let id):
            return appFailure("002", kind: "AlreadyDischarged", "O paciente \(id) ja esta desligado.", category: .conflict, severity: .warning, http: 409)
        case .patientIsActive(let id):
            return appFailure("003", kind: "PatientIsActive", "Paciente ativo \(id) nao pode ser retirado da fila. Use discharge.", category: .conflict, severity: .warning, http: 409)
        case .invalidReason(let value):
            return appFailure("004", kind: "InvalidReason", "Motivo de retirada invalido: '\(value)'.", category: .domainRuleViolation, severity: .warning, http: 400)
        case .notesRequiredForOtherReason:
            return appFailure("005", kind: "NotesRequiredForOtherReason", "Observacoes sao obrigatorias quando o motivo e 'outro'.", category: .domainRuleViolation, severity: .warning, http: 400)
        case .notesExceedMaxLength(let length):
            return appFailure("006", kind: "NotesExceedMaxLength", "Observacoes excedem o limite de 1000 caracteres (informado: \(length)).", category: .domainRuleViolation, severity: .warning, http: 400)
        case .invalidPatientIdFormat(let value):
            return appFailure("007", kind: "InvalidPatientIdFormat", "Formato de ID do paciente invalido: '\(value)'.", category: .dataConsistencyIncident, severity: .error, http: 400)
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "withdraw_from_waitlist"]),
            http: http
        )
    }
}
