import Foundation

public enum LookupRequestError: Error, Sendable, Equatable {
    case requestNotFound(String)
    case requestAlreadyReviewed(String)
    case codigoAlreadyExists(table: String, codigo: String)
    case invalidTableName(String)
    case invalidCodigoFormat(String)
    case emptyJustificativa
    case emptyReviewNote
    case emptyDescricao
    case invalidRequestId(String)
}

extension LookupRequestError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/configuration"
    private static let codePrefix = "LKR"

    public var asAppError: AppError {
        switch self {
        case .requestNotFound(let id):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Lookup request not found.",
                bc: Self.bc, module: Self.module, kind: "RequestNotFound",
                context: ["id": .init(id)], safeContext: [:],
                observability: .init(category: .dataConsistencyIncident, severity: .error,
                    fingerprint: ["\(Self.codePrefix)-001"], tags: ["layer": "configuration"]),
                http: 404
            )
        case .requestAlreadyReviewed(let id):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Request has already been reviewed.",
                bc: Self.bc, module: Self.module, kind: "RequestAlreadyReviewed",
                context: ["id": .init(id)], safeContext: [:],
                observability: .init(category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-002"], tags: ["layer": "configuration"]),
                http: 409
            )
        case .codigoAlreadyExists(let table, let codigo):
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "Code '\(codigo)' already exists in table '\(table)'.",
                bc: Self.bc, module: Self.module, kind: "CodigoAlreadyExists",
                context: ["table": .init(table), "codigo": .init(codigo)], safeContext: ["table": .init(table)],
                observability: .init(category: .conflict, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-003"], tags: ["layer": "configuration"]),
                http: 409
            )
        case .invalidTableName(let table):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "Lookup table '\(table)' is not allowed.",
                bc: Self.bc, module: Self.module, kind: "InvalidTableName",
                context: ["table": .init(table)], safeContext: ["table": .init(table)],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-004"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .invalidCodigoFormat(let codigo):
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "Invalid code format. Expected UPPER_SNAKE_CASE.",
                bc: Self.bc, module: Self.module, kind: "InvalidCodigoFormat",
                context: ["codigo": .init(codigo)], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-005"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .emptyJustificativa:
            return AppError(
                code: "\(Self.codePrefix)-006",
                message: "Justificativa cannot be empty.",
                bc: Self.bc, module: Self.module, kind: "EmptyJustificativa",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-006"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .emptyReviewNote:
            return AppError(
                code: "\(Self.codePrefix)-007",
                message: "Review note cannot be empty when rejecting a request.",
                bc: Self.bc, module: Self.module, kind: "EmptyReviewNote",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-007"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .emptyDescricao:
            return AppError(
                code: "\(Self.codePrefix)-008",
                message: "Description cannot be empty.",
                bc: Self.bc, module: Self.module, kind: "EmptyDescricao",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-008"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .invalidRequestId(let id):
            return AppError(
                code: "\(Self.codePrefix)-009",
                message: "Invalid request ID format.",
                bc: Self.bc, module: Self.module, kind: "InvalidRequestId",
                context: ["id": .init(id)], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-009"], tags: ["layer": "configuration"]),
                http: 400
            )
        }
    }
}
