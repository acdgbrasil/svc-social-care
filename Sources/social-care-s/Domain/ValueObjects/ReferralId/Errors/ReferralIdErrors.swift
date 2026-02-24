import Foundation

public enum RIE {
    private static let bc = "SOCIAL"
    private static let module = "social-care/referral-id"
    private static let codePrefix = "RI"

    public static func invalidFormat(_ value: String) -> AppError {
        return AppError(
            code: "\(codePrefix)-001",
            message: "O valor fornecido ('\(value)') não é um identificador de encaminhamento válido.",
            bc: bc, module: module, kind: "InvalidFormat",
            context: ["providedValue": AnySendable(value)],
            safeContext: ["providedValue": AnySendable(value)],
            observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(codePrefix)-001"], tags: ["vo": "referral_id"]),
            http: 422
        )
    }
}
