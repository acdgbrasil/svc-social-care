import Foundation

public enum PatientError: Error, Sendable, Equatable {
    case initialIdIsRequired
    case initialPersonIdIsRequired
    case initialDiagnosesCantBeEmpty
    case familyMemberAlreadyExists(memberId: String)
    case familyMemberNotFound(personId: String)
    case referralTargetOutsideBoundary(targetId: String)
    case violationTargetOutsideBoundary(targetId: String)
}

extension PatientError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/patient"
    private static let codePrefix = "PAT"

    public var asAppError: AppError {
        switch self {
        case .initialIdIsRequired:
            return appFailure("001", "ID inicial é obrigatório.")
        case .initialPersonIdIsRequired:
            return appFailure("002", "PersonId inicial é obrigatório.")
        case .initialDiagnosesCantBeEmpty:
            return appFailure("003", "A lista de diagnósticos inicial não pode estar vazia.")
        case .familyMemberAlreadyExists(let memberId):
            return appFailure("004", "Membro familiar já existe: \(memberId).", context: ["memberId": memberId])
        case .familyMemberNotFound(let personId):
            return appFailure("005", "Membro familiar não encontrado para a pessoa: \(personId).", context: ["personId": personId])
        case .referralTargetOutsideBoundary(let targetId):
            return appFailure("006", "O alvo do encaminhamento (\(targetId)) está fora da fronteira do agregado.")
        case .violationTargetOutsideBoundary(let targetId):
            return appFailure("007", "A vítima da violação (\(targetId)) está fora da fronteira do agregado.")
        }
    }

    private func appFailure(_ subCode: String, _ message: String, context: [String: Any] = [:]) -> AppError {
        return AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: "DomainError",
            context: context.mapValues { AnySendable($0) },
            safeContext: [:],
            observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["aggregate": "patient"]),
            http: 422
        )
    }
}
