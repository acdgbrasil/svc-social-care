import Foundation

/// Fábrica de erros para a Entidade Referral.
public enum ReferralError: Error, Sendable, Equatable {
    case dateInFuture
    case reasonMissing
    case invalidStatusTransition(from: String, to: String)
}

extension ReferralError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/referral"
    private static let codePrefix = "REF"

    public var asAppError: AppError {
        switch self {
        case .dateInFuture:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A data do encaminhamento não pode estar no futuro.",
                bc: Self.bc, module: Self.module, kind: "DateInFuture",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["entity": "referral"]),
                http: 422
            )
        case .reasonMissing:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O motivo do encaminhamento deve ser informado.",
                bc: Self.bc, module: Self.module, kind: "ReasonMissing",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["entity": "referral"]),
                http: 422
            )
        case .invalidStatusTransition(let from, let to):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "Transição de status inválida de \(from) para \(to). Apenas encaminhamentos pendentes podem ser finalizados ou cancelados.",
                bc: Self.bc, module: Self.module, kind: "InvalidStatusTransition",
                context: ["from": AnySendable(from), "to": AnySendable(to)],
                safeContext: ["from": AnySendable(from), "to": AnySendable(to)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-003"], tags: ["entity": "referral"]),
                http: 422
            )
        }
    }
}
