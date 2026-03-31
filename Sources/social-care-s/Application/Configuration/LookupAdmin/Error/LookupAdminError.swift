import Foundation

public enum LookupAdminError: Error, Sendable, Equatable {
    case tableNotAllowed(String)
    case invalidCodigoFormat(String)
    case codigoAlreadyExists(table: String, codigo: String)
    case itemNotFound(table: String, id: String)
    case itemReferencedByPatients(table: String, id: String)
    case invalidItemId(String)
}

extension LookupAdminError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/configuration"
    private static let codePrefix = "LKP"

    public var asAppError: AppError {
        switch self {
        case .tableNotAllowed(let table):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Lookup table '\(table)' is not allowed.",
                bc: Self.bc, module: Self.module, kind: "TableNotAllowed",
                context: ["table": .init(table)], safeContext: ["table": .init(table)],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-001"], tags: ["layer": "configuration"]),
                http: 400
            )
        case .invalidCodigoFormat(let codigo):
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Invalid code format. Expected UPPER_SNAKE_CASE.",
                bc: Self.bc, module: Self.module, kind: "InvalidCodigoFormat",
                context: ["codigo": .init(codigo)], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-002"], tags: ["layer": "configuration"]),
                http: 400
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
        case .itemNotFound(let table, let id):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "Item not found in table '\(table)'.",
                bc: Self.bc, module: Self.module, kind: "ItemNotFound",
                context: ["table": .init(table), "id": .init(id)], safeContext: ["table": .init(table)],
                observability: .init(category: .dataConsistencyIncident, severity: .error,
                    fingerprint: ["\(Self.codePrefix)-004"], tags: ["layer": "configuration"]),
                http: 404
            )
        case .itemReferencedByPatients(let table, let id):
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "Cannot deactivate item: it is referenced by patient records.",
                bc: Self.bc, module: Self.module, kind: "ItemReferencedByPatients",
                context: ["table": .init(table), "id": .init(id)], safeContext: ["table": .init(table)],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-005"], tags: ["layer": "configuration"]),
                http: 409
            )
        case .invalidItemId(let id):
            return AppError(
                code: "\(Self.codePrefix)-006",
                message: "Invalid item ID format.",
                bc: Self.bc, module: Self.module, kind: "InvalidItemId",
                context: ["id": .init(id)], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning,
                    fingerprint: ["\(Self.codePrefix)-006"], tags: ["layer": "configuration"]),
                http: 400
            )
        }
    }
}
