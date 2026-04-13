import Foundation

/// Erros específicos para o caso de uso de desligamento de paciente.
public enum DischargePatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyDischarged(String)
    case invalidReason(String)
    case notesRequiredForOtherReason
    case notesExceedMaxLength(Int)
    case invalidPatientIdFormat(String)
}

extension DischargePatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "DISC"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound(let id):
            return appFailure("004", kind: "PatientNotFound", "Paciente não encontrado: \(id).", category: .domainRuleViolation, severity: .warning, http: 404)
        case .alreadyDischarged(let id):
            return appFailure("001", kind: "AlreadyDischarged", "O paciente \(id) já está desligado.", category: .conflict, severity: .warning, http: 409)
        case .invalidReason(let value):
            return appFailure("002", kind: "InvalidReason", "Motivo de desligamento inválido: '\(value)'.", category: .domainRuleViolation, severity: .warning, http: 400)
        case .notesRequiredForOtherReason:
            return appFailure("003", kind: "NotesRequiredForOtherReason", "Observações são obrigatórias quando o motivo é 'outro'.", category: .domainRuleViolation, severity: .warning, http: 400)
        case .notesExceedMaxLength(let length):
            return appFailure("005", kind: "NotesExceedMaxLength", "Observações excedem o limite de 1000 caracteres (informado: \(length)).", category: .domainRuleViolation, severity: .warning, http: 400)
        case .invalidPatientIdFormat(let value):
            return appFailure("006", kind: "InvalidPatientIdFormat", "Formato de ID do paciente inválido: '\(value)'.", category: .dataConsistencyIncident, severity: .error, http: 400)
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "discharge_patient"]),
            http: http
        )
    }
}
