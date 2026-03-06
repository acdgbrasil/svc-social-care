import Foundation

public enum AIE {
    private static let bc = "SOCIAL"
    private static let module = "social-care/appointment-id"
    private static let codePrefix = "AI"

    public static func invalidFormat(_ value: String) -> AppError {
        return AppError(
            code: "\(codePrefix)-001",
            message: "O valor fornecido ('\(value)') não é um identificador de atendimento válido.",
            bc: bc, module: module, kind: "InvalidFormat",
            context: ["providedValue": AnySendable(value)],
            safeContext: ["providedValue": AnySendable(value)],
            observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(codePrefix)-001"], tags: ["vo": "appointment_id"]),
            http: 422
        )
    }
}
