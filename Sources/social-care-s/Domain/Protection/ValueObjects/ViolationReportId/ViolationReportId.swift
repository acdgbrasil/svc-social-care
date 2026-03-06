import Foundation

public enum ViolationReportIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension ViolationReportIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/violation-report-id"
    private static let codePrefix = "VRI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de relatório de violação válido.",
                bc: Self.bc, module: Self.module, kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "violation_report_id"]),
                http: 422
            )
        }
    }
}

/// Um Value Object que representa o identificador único de um relatório de violação de direitos.
public struct ViolationReportId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    public static let brand = "ViolationReportId"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw ViolationReportIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
