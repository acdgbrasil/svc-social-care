import Foundation

public enum RightsViolationReportError: Error, Sendable, Equatable {
    case reportDateInFuture
    case incidentAfterReport
    case emptyDescription
}

extension RightsViolationReportError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/rights-violation"
    private static let codePrefix = "RVR"

    public var asAppError: AppError {
        switch self {
        case .reportDateInFuture:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "A data do relatório não pode estar no futuro.",
                bc: Self.bc, module: Self.module, kind: "ReportDateInFuture",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["entity": "rights_violation"]),
                http: 422
            )
        case .incidentAfterReport:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "A data do incidente não pode ser posterior à data do relatório.",
                bc: Self.bc, module: Self.module, kind: "IncidentAfterReport",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["entity": "rights_violation"]),
                http: 422
            )
        case .emptyDescription:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "A descrição dos fatos não pode ser vazia.",
                bc: Self.bc, module: Self.module, kind: "EmptyDescription",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["entity": "rights_violation"]),
                http: 422
            )
        }
    }
}
