import Foundation

/// Erros específicos para o Value Object HousingCondition.
public enum HousingConditionError: Error, Sendable, Equatable {
    case negativeRooms
    case negativeBathrooms
    case bathroomsExceedRooms
}

extension HousingConditionError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/housing-condition"
    private static let codePrefix = "HC"

    public var asAppError: AppError {
        switch self {
        case .negativeRooms:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O número de cômodos não pode ser negativo.",
                bc: Self.bc, module: Self.module, kind: "NegativeRooms",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "housing_condition"]),
                http: 422
            )
        case .negativeBathrooms:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O número de banheiros não pode ser negativo.",
                bc: Self.bc, module: Self.module, kind: "NegativeBathrooms",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "housing_condition"]),
                http: 422
            )
        case .bathroomsExceedRooms:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "O número de banheiros não pode exceder o número total de cômodos.",
                bc: Self.bc, module: Self.module, kind: "BathroomsExceedRooms",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "housing_condition"]),
                http: 422
            )
        }
    }
}
