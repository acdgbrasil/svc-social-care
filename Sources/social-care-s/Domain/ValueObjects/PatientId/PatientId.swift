import Foundation

public enum PatientIdError: Error, Sendable, Equatable {
    case invalidFormat(String)
}

extension PatientIdError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/patient-id"
    private static let codePrefix = "PAI"

    public var asAppError: AppError {
        switch self {
        case .invalidFormat(let value):
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O valor fornecido ('\(value)') não é um identificador de paciente válido.",
                bc: Self.bc, module: Self.module, kind: "InvalidFormat",
                context: ["providedValue": AnySendable(value)],
                safeContext: ["providedValue": AnySendable(value)],
                observability: .init(category: .domainRuleViolation, severity: .error, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "patient_id"]),
                http: 422
            )
        }
    }
}

public struct PatientId: Codable, Sendable, Hashable, Equatable, CustomStringConvertible {
    public static let brand = "PatientId"
    private let value: String
    public var description: String { value }
    
    public init(_ rawValue: String) throws {
        let sanitized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard UUID(uuidString: sanitized) != nil else {
            throw PatientIdError.invalidFormat(sanitized)
        }
        self.value = sanitized
    }

    public init() {
        self.value = UUID().uuidString.lowercased()
    }
}
