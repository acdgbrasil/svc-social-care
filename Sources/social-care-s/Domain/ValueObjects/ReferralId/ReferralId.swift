import Foundation

public enum ReferralIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension ReferralIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/referral-id"
    private static let codePrefix = "RI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de encaminhamento válido.",
                bc: Self.bc, module: Self.module, kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "referral_id"]),
                http: 422
            )
        }
    }
}

/// Um Value Object que representa o identificador único de um encaminhamento.
public struct ReferralId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    public static let brand = "ReferralId"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw ReferralIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
