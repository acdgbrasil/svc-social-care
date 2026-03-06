import Foundation

public enum PersonalDataError: Error, Sendable, Equatable {
    case firstNameEmpty
    case lastNameEmpty
    case motherNameEmpty
    case nationalityEmpty
    case birthDateInFuture(date: String, now: String)
}

extension PersonalDataError: AppErrorConvertible {
    private static let bc = "SOCIAL"
    private static let module = "social-care/personal-data"
    private static let codePrefix = "PDT"

    public var asAppError: AppError {
        switch self {
        case .firstNameEmpty:
            return AppError(
                code: "\(Self.codePrefix)-001",
                message: "O primeiro nome nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "FirstNameEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-001"], tags: ["vo": "personal_data"]),
                http: 422
            )
        case .lastNameEmpty:
            return AppError(
                code: "\(Self.codePrefix)-002",
                message: "O sobrenome nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "LastNameEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-002"], tags: ["vo": "personal_data"]),
                http: 422
            )
        case .motherNameEmpty:
            return AppError(
                code: "\(Self.codePrefix)-003",
                message: "O nome da mae nao pode ser vazio.",
                bc: Self.bc, module: Self.module, kind: "MotherNameEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-003"], tags: ["vo": "personal_data"]),
                http: 422
            )
        case .nationalityEmpty:
            return AppError(
                code: "\(Self.codePrefix)-005",
                message: "A nacionalidade nao pode ser vazia.",
                bc: Self.bc, module: Self.module, kind: "NationalityEmpty",
                context: [:], safeContext: [:],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-005"], tags: ["vo": "personal_data"]),
                http: 422
            )
        case .birthDateInFuture(let date, let now):
            return AppError(
                code: "\(Self.codePrefix)-004",
                message: "A data de nascimento nao pode estar no futuro.",
                bc: Self.bc, module: Self.module, kind: "BirthDateInFuture",
                context: ["date": AnySendable(date), "now": AnySendable(now)],
                safeContext: ["date": AnySendable(date), "now": AnySendable(now)],
                observability: .init(category: .domainRuleViolation, severity: .warning, fingerprint: ["\(Self.codePrefix)-004"], tags: ["vo": "personal_data"]),
                http: 422
            )
        }
    }
}
