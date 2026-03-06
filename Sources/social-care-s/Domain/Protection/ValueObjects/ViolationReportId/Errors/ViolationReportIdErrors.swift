import Foundation

public enum VRIE {
    private static let bc = "SOCIAL"
    private static let module = "social-care/violation-report-id"
    private static let codePrefix = "VRI"

    public static func invalidFormat(_ value: String) -> AppError {
        return AppError(
            code: "\(codePrefix)-001",
            message: "O valor fornecido ('\(value)') não é um identificador de relatório de violação válido.",
            bc: bc, module: module, kind: "InvalidFormat",
            context: ["providedValue": AnySendable(value)],
            safeContext: ["providedValue": AnySendable(value)],
            observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(codePrefix)-001"], tags: ["vo": "violation_report_id"]),
            http: 422
        )
    }
}
