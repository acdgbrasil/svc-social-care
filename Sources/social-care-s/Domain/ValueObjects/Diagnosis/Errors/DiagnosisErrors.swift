import Foundation

/// Erros específicos para o Value Object Diagnosis.
public enum DiagnosisError: Error, Sendable, Equatable {
    case dateInFuture(date: String, now: String)
    case dateBeforeYearZero(year: Int)
    case descriptionEmpty
}

extension DiagnosisError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/diagnosis"
    private static let codePrefix = "DIA"

    public var asAppError: AppError {
        switch self {
        case .dateInFuture(let date, let now):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A data do diagnóstico (\(date)) não pode estar no futuro (\(now)).",
                bc: Self.bc, module: Self.module, kind: "DateInFuture",
                context: ["date": AnySendable(date), "now": AnySendable(now)],
                safeContext: ["date": AnySendable(date), "now": AnySendable(now)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "diagnosis"]),
                http: 422
            )
        case .dateBeforeYearZero(let year):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O ano do diagnóstico (\(year)) é inválido.",
                bc: Self.bc, module: Self.module, kind: "DateBeforeYearZero",
                context: ["year": AnySendable(year)],
                safeContext: ["year": AnySendable(year)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "diagnosis"]),
                http: 422
            )
        case .descriptionEmpty:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "A descrição do diagnóstico não pode ser vazia.",
                bc: Self.bc, module: Self.module, kind: "DescriptionEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "diagnosis"]),
                http: 422
            )
        }
    }
}
