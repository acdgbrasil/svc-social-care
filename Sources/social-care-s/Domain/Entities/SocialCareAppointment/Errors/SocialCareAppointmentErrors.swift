import Foundation

public enum SocialCareAppointmentError: Error, Sendable, Equatable {
    case dateInFuture
    case invalidType(received: String, expected: String)
    case missingNarrative
    case summaryTooLong(limit: Int)
    case actionPlanTooLong(limit: Int)
}

extension SocialCareAppointmentError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/appointment"
    private static let codePrefix = "SCA"

    public var asAppError: AppError {
        switch self {
        case .dateInFuture:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A data do atendimento não pode estar no futuro.",
                bc: Self.bc, module: Self.module, kind: "DateInFuture",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["entity": "appointment"]),
                http: 422
            )
        case .invalidType(let received, let expected):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Tipo de atendimento inválido: \(received). Esperado: \(expected).",
                bc: Self.bc, module: Self.module, kind: "InvalidType",
                context: ["received": AnySendable(received), "expected": AnySendable(expected)],
                safeContext: ["received": AnySendable(received)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-002"], tags: ["entity": "appointment"]),
                http: 422
            )
        case .missingNarrative:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "O atendimento deve possuir ao menos um resumo ou um plano de ação.",
                bc: Self.bc, module: Self.module, kind: "MissingNarrative",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["entity": "appointment"]),
                http: 422
            )
        case .summaryTooLong(let limit):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "O resumo excede o limite de \(limit) caracteres.",
                bc: Self.bc, module: Self.module, kind: "SummaryTooLong",
                context: ["limit": AnySendable(limit)],
                safeContext: ["limit": AnySendable(limit)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["entity": "appointment"]),
                http: 422
            )
        case .actionPlanTooLong(let limit):
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "O plano de ação excede o limite de \(limit) caracteres.",
                bc: Self.bc, module: Self.module, kind: "ActionPlanTooLong",
                context: ["limit": AnySendable(limit)],
                safeContext: ["limit": AnySendable(limit)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["entity": "appointment"]),
                http: 422
            )
        }
    }
}
