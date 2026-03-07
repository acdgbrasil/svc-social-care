import Foundation

/// Erros específicos para o Value Object HousingCondition.
public enum HousingConditionError: Error, Sendable, Equatable {
    case negativeRooms
    case negativeBedrooms
    case negativeBathrooms
    case bedroomsExceedRooms
    case bathroomsExceedRooms
}

extension HousingConditionError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/housing-condition"
    private static let codePrefix = "HC"

    public var asAppError: AppError {
        switch self {
        case .negativeRooms:
            return appFailure("001", "O numero de comodos nao pode ser negativo.", kind: "NegativeRooms")
        case .negativeBedrooms:
            return appFailure("002", "O numero de dormitorios nao pode ser negativo.", kind: "NegativeBedrooms")
        case .negativeBathrooms:
            return appFailure("003", "O numero de banheiros nao pode ser negativo.", kind: "NegativeBathrooms")
        case .bedroomsExceedRooms:
            return appFailure("004", "O numero de dormitorios nao pode exceder o numero total de comodos.", kind: "BedroomsExceedRooms")
        case .bathroomsExceedRooms:
            return appFailure("005", "O numero de banheiros nao pode exceder o numero total de comodos.", kind: "BathroomsExceedRooms")
        }
    }

    private func appFailure(_ subCode: String, _ message: String, kind: String) -> AppError {
        return AppError(
            code: "\(Self.codePrefix)-\(subCode)",
            message: message,
            bc: Self.bc, module: Self.module, kind: kind,
            context: [:], safeContext: [:],
            observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-\(subCode)"], tags: ["vo": "housing_condition"]),
            http: 422
        )
    }
}
