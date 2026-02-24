import Foundation

public enum ProfessionalIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension ProfessionalIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/professional-id"
    private static let codePrefix = "PRI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de profissional válido.",
                bc: Self.bc, module: Self.module, kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "professional_id"]),
                http: 422
            )
        }
    }
}

/// Um Value Object que representa o identificador único de um profissional.
public struct ProfessionalId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    public static let brand = "ProfessionalId"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw ProfessionalIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
