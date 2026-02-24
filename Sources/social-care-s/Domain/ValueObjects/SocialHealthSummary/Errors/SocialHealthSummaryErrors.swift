import Foundation

/// Erros específicos para o Value Object SocialHealthSummary.
public enum SocialHealthSummaryError: Error, Sendable, Equatable {
    case functionalDependenciesEmpty
}

extension SocialHealthSummaryError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/social-health-summary"
    private static let codePrefix = "SHS"

    public var asAppError: AppError {
        switch self {
        case .functionalDependenciesEmpty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Uma ou mais dependências funcionais fornecidas estão vazias.",
                bc: Self.bc, module: Self.module, kind: "FunctionalDependenciesEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "social_health_summary"]),
                http: 422
            )
        }
    }
}
