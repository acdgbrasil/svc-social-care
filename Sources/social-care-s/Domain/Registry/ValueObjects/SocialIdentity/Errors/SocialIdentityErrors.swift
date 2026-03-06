import Foundation

public enum SocialIdentityError: Error, Sendable, Equatable {
    case indigenousInVillageMissingDescription
    case indigenousOutsideVillageMissingDescription
    case descriptionRequiredForOtherType
}

extension SocialIdentityError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/social-identity"
    private static let codePrefix = "SID"

    public var asAppError: AppError {
        switch self {
        case .indigenousInVillageMissingDescription:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "Família indígena residente em aldeia ou reserva requer descrição da aldeia.",
                bc: Self.bc, module: Self.module, kind: "IndigenousInVillageMissingDescription",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "social_identity"]),
                http: 422
            )
        case .indigenousOutsideVillageMissingDescription:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "Família indígena não residente em aldeia requer descrição complementar.",
                bc: Self.bc, module: Self.module, kind: "IndigenousOutsideVillageMissingDescription",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "social_identity"]),
                http: 422
            )
        case .descriptionRequiredForOtherType:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "A descrição detalhada é obrigatória para este tipo de identidade social.",
                bc: Self.bc, module: Self.module, kind: "DescriptionRequiredForOtherType",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "social_identity"]),
                http: 422
            )
        }
    }
}
