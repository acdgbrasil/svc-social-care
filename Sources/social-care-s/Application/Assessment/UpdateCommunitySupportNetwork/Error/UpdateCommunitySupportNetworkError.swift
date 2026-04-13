import Foundation

public enum UpdateCommunitySupportNetworkError: Error, Sendable, Equatable {
    case patientNotFound
    case invalidPersonIdFormat(String)
    case familyConflictsWhitespace
    case familyConflictsTooLong(limit: Int)
    case unexpectedFailure(String)
    case patientNotActive(reason: String)
}

extension UpdateCommunitySupportNetworkError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/application"
    private static let codePrefix = "UCSN"

    public var asAppError: AppError {
        switch self {
        case .patientNotFound:
            return appFailure("001", kind: "PatientNotFound", "O paciente não foi encontrado.", http: 404)
        case .invalidPersonIdFormat(let value):
            return appFailure("002", kind: "InvalidPersonIdFormat", "ID de pessoa inválido: \(value)", http: 400)
        case .familyConflictsWhitespace:
            return appFailure("003", kind: "FamilyConflictsWhitespace", "O campo de conflitos familiares não pode conter apenas espaços.", http: 422)
        case .familyConflictsTooLong(let limit):
            return appFailure("004", kind: "FamilyConflictsTooLong", "O campo de conflitos familiares excede o limite de \(limit) caracteres.", http: 422)
        case .patientNotActive(let reason):
            return appFailure("005", kind: "PatientNotActive", "Operação não permitida: \(reason)", http: 409)
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
            observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["use_case": "update_community_support_network"]),
            http: http
        )
    }
}
