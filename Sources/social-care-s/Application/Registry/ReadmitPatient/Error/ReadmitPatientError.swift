import Foundation

/// Erros específicos para o caso de uso de readmissão de paciente.
public enum ReadmitPatientError: Error, Sendable, Equatable {
    case patientNotFound(String)
    case alreadyActive(String)
    case invalidPatientIdFormat(String)
    case notesExceedMaxLength(Int)
    case cannotReadmitWaitlisted(String)
}

extension ReadmitPatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "READM"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound(let id):
            return appFailure("002", kind: "PatientNotFound", "Paciente não encontrado.", category: .domainRuleViolation, severity: .warning, http: 404, context: ["patientId": id])
        case .alreadyActive(let id):
            return appFailure("001", kind: "AlreadyActive", "O paciente já está ativo.", category: .conflict, severity: .warning, http: 409, context: ["patientId": id])
        case .invalidPatientIdFormat(let value):
            return appFailure("003", kind: "InvalidPatientIdFormat", "Formato de ID do paciente inválido: '\(value)'.", category: .dataConsistencyIncident, severity: .error, http: 400)
        case .notesExceedMaxLength(let length):
            return appFailure("004", kind: "NotesExceedMaxLength", "Observações excedem o limite de 1000 caracteres (informado: \(length)).", category: .domainRuleViolation, severity: .warning, http: 400)
        case .cannotReadmitWaitlisted:
            return appFailure("005", kind: "CannotReadmitWaitlisted", "Paciente em lista de espera não pode ser readmitido. Use admit.", category: .conflict, severity: .warning, http: 409)
        }
    }

    private func appFailure(_ subCode: String, kind: String, _ message: String, category: AppError.Category, severity: AppError.Severity, http: Int, context: [String: Any] = [:]) -> AppError {
        AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: category, severity: severity, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "readmit_patient"]),
            http: http
        )
    }
}
